<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Contacts</title>
        <link rel='stylesheet' href='{{ asset('css/contacts.css') }}'>
</head>
<body>
    <div class="card">
        <h1>Contacts</h1>
        <div class="form">
            <input type="text" id="nameInput" placeholder="Name">
            <input type="email" id="emailInput" placeholder="Email">
            <input type="text" id="phoneInput" placeholder="Phone">
            <button id="addBtn">Add</button>
        </div>
        <table>
            <thead><tr><th>Name</th><th>Email</th><th>Phone</th><th></th></tr></thead>
            <tbody id="contactsBody"></tbody>
        </table>
        <div id="empty" class="empty">No contacts yet</div>
    </div>
        <script src='{{ asset('js/contacts.js') }}'></script>
</body>
</html>


