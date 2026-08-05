import msvcrt
from terminal import TerminalAdapter


class WindowsTerminal(TerminalAdapter):

    def setup(self):
        pass

    def get_key(self):
        if msvcrt.kbhit():
            key = msvcrt.getch()
            if key == b" ":
                return " "
            try:
                return key.decode().lower()
            except UnicodeDecodeError:
                return ""
        return ""

    def restore(self):
        pass
