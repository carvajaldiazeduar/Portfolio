import reflex as rx


class State(rx.State):
    display: str = "0"
    previous: float = 0.0
    operator: str = ""
    waiting: bool = False

    def input_digit(self, digit: str):
        if self.waiting:
            self.display = digit
            self.waiting = False
        else:
            if self.display == "0":
                self.display = digit
            else:
                self.display += digit

    def input_decimal(self):
        if self.waiting:
            self.display = "0."
            self.waiting = False
            return
        if "." not in self.display:
            self.display += "."

    def set_operator(self, op: str):
        self.previous = float(self.display)
        self.operator = op
        self.waiting = True

    def calculate(self):
        current = float(self.display)
        if self.operator == "+":
            result = self.previous + current
        elif self.operator == "-":
            result = self.previous - current
        elif self.operator == "*":
            result = self.previous * current
        elif self.operator == "/":
            result = "Error" if current == 0 else self.previous / current
        else:
            result = current
        self.display = str(result)
        self.operator = ""
        self.waiting = False

    def clear(self):
        self.display = "0"
        self.previous = 0.0
        self.operator = ""
        self.waiting = False


def btn(label, on_click, bg="gray"):
    return rx.button(
        label,
        on_click=on_click,
        width="100%",
        padding="1.5rem 0",
        font_size="1.3rem",
        border_radius="8px",
        background=bg,
        color="white" if bg != "#d4d4d2" else "#333",
        cursor="pointer",
        _hover={"filter": "brightness(0.9)"},
    )


def row(*buttons):
    return rx.hstack(*buttons, spacing="2", width="100%")


def index():
    return rx.center(
        rx.vstack(
            rx.heading("Calculator", size="3", color="white"),
            rx.box(
                rx.text(
                    State.display,
                    font_size="2.5rem",
                    color="white",
                    text_align="right",
                    font_family="monospace",
                ),
                background="#2c2c2c",
                padding="1rem 1.5rem",
                border_radius="10px",
                width="100%",
                min_height="70px",
                display="flex",
                align_items="center",
                justify_content="flex-end",
            ),
            row(
                btn("7", State.input_digit("7")),
                btn("8", State.input_digit("8")),
                btn("9", State.input_digit("9")),
                btn("÷", State.set_operator("/"), "#f5923e"),
            ),
            row(
                btn("4", State.input_digit("4")),
                btn("5", State.input_digit("5")),
                btn("6", State.input_digit("6")),
                btn("×", State.set_operator("*"), "#f5923e"),
            ),
            row(
                btn("1", State.input_digit("1")),
                btn("2", State.input_digit("2")),
                btn("3", State.input_digit("3")),
                btn("-", State.set_operator("-"), "#f5923e"),
            ),
            row(
                btn("0", State.input_digit("0")),
                btn(".", State.input_decimal),
                btn("=", State.calculate, "#f5923e"),
                btn("+", State.set_operator("+"), "#f5923e"),
            ),
            rx.hstack(
                btn("C", State.clear, "#d4d4d2"),
                btn("AC", State.clear, "#d4d4d2"),
                spacing="2",
                width="100%",
            ),
            spacing="3",
            width="100%",
        ),
        background="#1c1c1c",
        padding="2rem",
        border_radius="16px",
        max_width="380px",
        box_shadow="0 8px 30px rgba(0,0,0,0.3)",
        margin_top="10vh",
    )


app = rx.App()
app.add_page(index, route="/")
