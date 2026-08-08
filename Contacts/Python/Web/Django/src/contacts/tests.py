import json

from django.test import TestCase
from django.test import override_settings

from .models import Contact


@override_settings(CACHES={'default': {'BACKEND': 'django.core.cache.backends.locmem.LocMemCache', 'LOCATION': 'contacts-tests'}})
class ContactApiTests(TestCase):
    def setUp(self):
        self.valid = {'name': 'Alice', 'phone': '123-4567', 'email': 'a@b.com'}

    def _post(self, data):
        return self.client.post('/api/contacts', data=json.dumps(data), content_type='application/json')

    def test_add_contact(self):
        rv = self._post(self.valid)
        self.assertEqual(rv.status_code, 201)
        self.assertEqual(Contact.objects.count(), 1)

    def test_add_contact_invalid_email(self):
        data = dict(self.valid, email='not-an-email')
        rv = self._post(data)
        self.assertEqual(rv.status_code, 400)
        body = rv.json()
        self.assertIn('email', body['errors'])
        self.assertEqual(body['errors']['email'], 'Invalid email format')
        self.assertEqual(Contact.objects.count(), 0)

    def test_add_contact_invalid_phone(self):
        data = dict(self.valid, phone='abc')
        rv = self._post(data)
        self.assertEqual(rv.status_code, 400)
        body = rv.json()
        self.assertIn('phone', body['errors'])
        self.assertEqual(body['errors']['phone'], 'Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)')

    def test_add_contact_missing_name(self):
        rv = self._post({'phone': '123-4567', 'email': 'a@b.com'})
        self.assertEqual(rv.status_code, 400)
        body = rv.json()
        self.assertIn('name', body['errors'])
        self.assertEqual(body['errors']['name'], 'Name is required')

    def test_add_contact_short_name(self):
        data = dict(self.valid, name='A')
        rv = self._post(data)
        self.assertEqual(rv.status_code, 400)
        body = rv.json()
        self.assertIn('name', body['errors'])

    def test_add_contact_invalid_json(self):
        rv = self.client.post('/api/contacts', data='{', content_type='application/json')
        self.assertEqual(rv.status_code, 400)
        body = rv.json()
        self.assertEqual(set(body['errors'].keys()), {'name', 'phone', 'email'})

    def test_add_contact_strips_input(self):
        data = {'name': '  Alice  ', 'phone': ' 123-4567 ', 'email': ' a@b.com '}
        rv = self._post(data)
        self.assertEqual(rv.status_code, 201)
        contact = Contact.objects.get()
        self.assertEqual(contact.name, 'Alice')
        self.assertEqual(contact.phone, '123-4567')
        self.assertEqual(contact.email, 'a@b.com')
