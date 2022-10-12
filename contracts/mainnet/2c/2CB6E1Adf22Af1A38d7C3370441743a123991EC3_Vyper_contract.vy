# @version 0.3.7
"""
@title Agent
@author CurveFi
"""


struct Message:
    target: address
    data: Bytes[MAX_BYTES]


MAX_BYTES: constant(uint256) = 1024
MAX_MESSAGES: constant(uint256) = 8


RELAYER: public(immutable(address))


@external
def __init__():
    RELAYER = msg.sender


@external
def execute(_messages: DynArray[Message, MAX_MESSAGES]):
    """
    @notice Execute a sequence of messages.
    @param _messages An array of messages to be executed.
    """
    assert msg.sender == RELAYER

    for message in _messages:
        raw_call(message.target, message.data)