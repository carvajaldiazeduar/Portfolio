import sys
import select
import termios
import tty
from terminal import TerminalAdapter


class UnixTerminal(TerminalAdapter):

    def setup(self):
        self.fd = sys.stdin.fileno()
        self.old_settings = termios.tcgetattr(self.fd)
        tty.setraw(self.fd)

    def get_key(self):
        if select.select([sys.stdin], [], [], 0.05)[0]:
            return sys.stdin.read(1).lower()
        return ""

    def restore(self):
        termios.tcsetattr(self.fd, termios.TCSADRAIN, self.old_settings)
