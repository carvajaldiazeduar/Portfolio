#!/usr/bin/env python3

from aws_cdk import App, Environment

from streamvideo_stack import StreamVideoStack

app = App()
_ = StreamVideoStack(
    app,
    "StreamVideo",
    env=Environment(
        account=app.node.try_get_context("account"),
        region=app.node.try_get_context("region"),
    ),
)

app.synth()