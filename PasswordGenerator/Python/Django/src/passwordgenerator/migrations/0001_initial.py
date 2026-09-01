from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = []

    operations = [
        migrations.CreateModel(
            name='PasswordEntry',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('password', models.CharField(max_length=500)),
                ('length', models.IntegerField(default=16)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
        ),
    ]
