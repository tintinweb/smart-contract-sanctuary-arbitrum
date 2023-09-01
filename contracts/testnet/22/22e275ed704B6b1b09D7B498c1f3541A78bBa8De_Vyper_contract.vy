# @version ^0.3

OWNER: immutable(address)
MAX_PAYLOADS: constant(uint256) = 16
MAX_PAYLOAD_BYTES: constant(uint256) = 1024

struct payload:
    target: address
    calldata: Bytes[MAX_PAYLOAD_BYTES]
    value: uint256

@external
@nonpayable
def __init__():
    OWNER = msg.sender

@external
@payable
def execute(
    payloads: DynArray[payload, MAX_PAYLOADS],
    return_on_first_failure: bool = False,
    execute_all_payloads: bool = False,
):

    assert msg.sender == OWNER, "!OWNER"

    success: bool = False
    response: Bytes[32] = b''

    for _payload in payloads:
        success, response = raw_call(
            _payload.target,
            _payload.calldata,
            max_outsize=32,
            value=_payload.value,
            revert_on_failure=False,
        )

        if execute_all_payloads:
            continue

        if not success:
            if return_on_first_failure:
                return
            else:
                raise


@external
@nonpayable
def getSender() -> address:
    return msg.sender