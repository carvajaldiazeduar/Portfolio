<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Inboxes</title>
        <link rel='stylesheet' href='{{ asset('css/inboxes.css') }}'>
</head>
<body>
    <div class="card">
        <h1>Inboxes</h1>
        <div class="form">
            <input type="text" id="subjectInput" placeholder="Subject">
            <textarea id="bodyInput" placeholder="Message body"></textarea>
            <button id="sendBtn">Send</button>
        </div>
        <ul class="messages" id="messagesList"></ul>
        <div id="empty" class="empty">No messages</div>
        <div id="detail" class="detail">
            <h3 id="detailSubject"></h3>
            <p id="detailBody"></p>
            <small id="detailTime"></small>
            <br>
            <button id="detailDelBtn" class="delBtn">Delete</button>
            <button id="detailCloseBtn" class="closeBtn">Close</button>
        </div>
    </div>
        <script src='{{ asset('js/inboxes.js') }}'></script>
</body>
</html>


