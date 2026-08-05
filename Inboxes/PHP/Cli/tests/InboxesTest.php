<?php

require_once __DIR__ . "/../inboxes.php";

use PHPUnit\Framework\TestCase;

class InboxesTest extends TestCase
{
    protected function setUp(): void
    {
        global $messages, $nextId;
        $messages = [];
        $nextId = 1;
    }

    public function testSendMessage()
    {
        $msg = sendMessage("alice", "Hello", "World");
        $this->assertEquals(1, $msg["id"]);
        $this->assertEquals("alice", $msg["from"]);
        $this->assertEquals("Hello", $msg["subject"]);
        $this->assertEquals("World", $msg["body"]);
        $this->assertFalse($msg["read"]);
        $this->assertNotNull($msg["created_at"]);
    }

    public function testListMessages()
    {
        sendMessage("alice", "Subject1", "Body1");
        sendMessage("bob", "Subject2", "Body2");
        $msgs = listMessages();
        $this->assertCount(2, $msgs);
    }

    public function testReadMessageMarksAsRead()
    {
        sendMessage("alice", "Test", "Body");
        $msg = readMessage(1);
        $this->assertNotNull($msg);
        $this->assertTrue($msg["read"]);
        $msg2 = readMessage(1);
        $this->assertTrue($msg2["read"]);
    }

    public function testDeleteMessage()
    {
        sendMessage("alice", "Del", "Me");
        $this->assertCount(1, listMessages());
        $this->assertTrue(deleteMessage(1));
        $this->assertCount(0, listMessages());
    }

    public function testListAfterDelete()
    {
        sendMessage("alice", "Keep", "Me");
        sendMessage("bob", "Delete", "This");
        deleteMessage(2);
        $msgs = listMessages();
        $this->assertCount(1, $msgs);
        $this->assertEquals(1, $msgs[0]["id"]);
    }

    public function testReadNonexistent()
    {
        $this->assertNull(readMessage(999));
    }

    public function testDeleteNonexistent()
    {
        $this->assertFalse(deleteMessage(999));
    }
}
