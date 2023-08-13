# @version 0.3.9

"""
@title StreamFactory
@author ApeWorX LTD.
@dev  The StreamFactory is a simple CREATE2 Factory for a given on-chain StreamManager
    ERC5202 blueprint deployment. Any call to `create` will create a new StreamManager
    deployment using the immutable initcode stored at `BLUEPRINT`. Only one deployment
    per account is allowed to be created, using the deployer's address for the CREATE2
    `salt`. Once the deployment is created, it is registered in the `deployments` view
    function for external reference.
"""
ONE_HOUR: constant(uint256) = 60 * 60
BLUEPRINT: public(immutable(address))

deployments: public(HashMap[address, address])


@external
def __init__(blueprint: address):
    BLUEPRINT = blueprint


@external
def create(validators: DynArray[address, 10], accepted_tokens: DynArray[address, 20]) -> address:
    #assert self.deployments[msg.sender] == empty(address)  # dev: only one deployment allowed

    deployment: address = create_from_blueprint(
        BLUEPRINT,
        msg.sender,  # Only caller can create
        ONE_HOUR,  # Safety parameter (not configurable)
        validators,
        accepted_tokens,  # whatever caller wants to accept
        salt=convert(msg.sender, bytes32),  # Ensures unique deployment per caller
        code_offset=3,
    )
    self.deployments[msg.sender] = deployment

    return deployment