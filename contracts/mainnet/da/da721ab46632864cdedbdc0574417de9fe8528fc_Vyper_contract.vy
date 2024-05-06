# @version 0.3.10


MAX_PAYLOAD: constant(uint256) = 10240

struct LogicCallArgs:
    logic_contract_address: address # the arbitrary contract address to external call
    payload: Bytes[MAX_PAYLOAD] # payloads

@external
@pure
def hash_function(args: LogicCallArgs, message_id: uint256, compass_id: bytes32, deadline: uint256) -> bytes32:
    return keccak256(_abi_encode(args, message_id, compass_id, deadline, method_id=method_id("logic_call((address,bytes),uint256,bytes32,uint256)")))