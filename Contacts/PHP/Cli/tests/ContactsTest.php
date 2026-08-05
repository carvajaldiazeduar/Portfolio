<?php

require_once __DIR__ . '/../contacts.php';

use PHPUnit\Framework\TestCase;

class ContactsTest extends TestCase
{
    public function testAddContact()
    {
        $contacts = [];
        addContact($contacts, "Alice", "123-456", "alice@test.com");
        $this->assertCount(1, $contacts);
        $this->assertEquals("Alice", $contacts[0]["name"]);
        $this->assertEquals("123-456", $contacts[0]["phone"]);
        $this->assertEquals("alice@test.com", $contacts[0]["email"]);
    }

    public function testSearchContactsFound()
    {
        $contacts = [
            ["name" => "Alice", "phone" => "123", "email" => "a@b.com"],
            ["name" => "Bob", "phone" => "456", "email" => "b@c.com"],
            ["name" => "Alexander", "phone" => "789", "email" => "alex@d.com"]
        ];
        $results = searchContacts($contacts, "al");
        $this->assertCount(2, $results);
    }

    public function testSearchContactsNotFound()
    {
        $contacts = [
            ["name" => "Alice", "phone" => "123", "email" => "a@b.com"]
        ];
        $this->expectOutputRegex('/No contacts/');
        $results = searchContacts($contacts, "zzz");
        $this->assertCount(0, $results);
    }

    public function testDeleteContactValid()
    {
        $contacts = [
            ["name" => "Alice", "phone" => "123", "email" => "a@b.com"],
            ["name" => "Bob", "phone" => "456", "email" => "b@c.com"]
        ];
        deleteContact($contacts, 0);
        $this->assertCount(1, $contacts);
        $this->assertEquals("Bob", $contacts[0]["name"]);
    }

    public function testDeleteContactInvalid()
    {
        $contacts = [
            ["name" => "Alice", "phone" => "123", "email" => "a@b.com"]
        ];
        $this->expectOutputRegex('/Invalid/');
        deleteContact($contacts, 5);
        $this->assertCount(1, $contacts);
    }

    public function testListContactsEmpty()
    {
        $this->expectOutputRegex('/No contacts/');
        listContacts([]);
    }
}
