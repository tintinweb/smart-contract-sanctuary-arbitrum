interface ChiToken {
    function transfer(address, uint256) external;
    function freeFromUpTo(address from, uint256 value) external;
    function mint(uint256 value) external;
    function balanceOf(address) external view returns(uint256);
}

contract automation{
    constructor(){}

    receive() external payable{}
    fallback() external payable{}
    bytes32[40] private gap;
    struct payloadType{
        bytes checkPayload;
        bytes execPayload;
        bool enabled;
    }
    mapping(address => payloadType) public payloads;
    address public owner;
    ChiToken public chi; 

    modifier onlyOwner(){
        require(owner == msg.sender, "access denied. owner ONLY.");
        _;
    }

    function initialize() external{
        address _owner = owner;
        require(_owner == address(0) || _owner == msg.sender, "failed initialize");
        if( _owner != msg.sender) _transferOwnership(msg.sender);

        uint256 id = getChainId();
        bool enableCHI;
        if( id == 0x01) enableCHI = true;       // ethereum
        else if( id == 0x38 ) enableCHI = true; // binance

        if( enableCHI == true ) chi = ChiToken(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
    }

    modifier discountCHI {
        uint256 gasStart = gasleft();
    _;
        if( address(chi) != address(0)){
            uint256 initialGas = 21000 + 16 * msg.data.length;
            uint256 gasSpent = initialGas + gasStart - gasleft();
            uint256 freeUpValue = (gasSpent + 14154) / 41130;

            chi.freeFromUpTo(msg.sender, freeUpValue);
        }
    }

    function add(address _target, bytes memory _checkPayload, bytes memory _execPayload) external onlyOwner{
        payloads[_target] = payloadType(_checkPayload, _execPayload, true);
    }

    function enable(address _target) external onlyOwner{
        payloadType memory payload = payloads[_target];
        require(payload.enabled == false, "already enabled.");
        require(payload.checkPayload.length > 0 && payload.execPayload.length > 0, "target does not exist.");
        payload.enabled = true;
        payloads[_target] = payload;
    }

    function disable(address _target) external onlyOwner{
        payloadType memory payload = payloads[_target];
        require(payload.enabled == true, "disabled.");
        require(payload.checkPayload.length > 0 && payload.execPayload.length > 0, "target does not exist.");
        payload.enabled = false;
        payloads[_target] = payload;
    }

    function transferOwnership(address to) external onlyOwner{
        _transferOwnership(to);
    }

    function performUpKeep(bytes calldata _performData) external payable discountCHI{
        (address target, bytes memory payload) = abi.decode(_performData, (address, bytes));
        (bool success, bytes memory data) = target.staticcall(abi.encodeWithSignature("owner()"));
        require(success == true && abi.decode(data, (address)) == owner, "You can call owner contract ONLY.");
        (success, data) = target.call{value: msg.value}(payload);
        require(success == true, "failed to call function");
    }

    function checkUpKeep(bytes calldata _checkData) external view returns(bool upKeepNeeded, bytes memory performData){
        (address target, bytes memory payload) = abi.decode(_checkData, (address, bytes));
        (bool success, bytes memory data) = target.staticcall(payload);
        require(success == true, "failed to call function");
        (upKeepNeeded, performData) = abi.decode(data, (bool, bytes));
    }

    function performUpkeepFixedPayload(bytes calldata _performData) external payable discountCHI{
        (address target) = abi.decode(_performData, (address));
        payloadType memory payload = payloads[target];
        require(payload.enabled == true, "disabled.");
        require(payload.checkPayload.length > 0 && payload.execPayload.length > 0, "target does not exist.");

        (bool success, bytes memory data) = target.call{value: msg.value}(payload.execPayload);
        require(success, "failed to call function");
    }

    function checkUpkeepFixedPayload(bytes calldata _checkData) external view returns(bool upkeepNeeded, bytes memory performData){
        (address target) = abi.decode(_checkData, (address));
        payloadType memory payload = payloads[target];
        require(payload.enabled == true, "disabled.");
        require(payload.checkPayload.length > 0 && payload.execPayload.length > 0, "target does not exist.");

        (bool success, bytes memory data) = target.staticcall(payload.checkPayload);
        require(success, "failed to call function");
        (upkeepNeeded) = abi.decode(data, (bool));
        performData = abi.encode(address(target));
    }

    function isEnabled(address _target) external view returns(bool){
        return payloads[_target].enabled;
    }

    function _transferOwnership(address to) internal{
        owner = to;
    }

    function getChainId() internal view returns(uint256){
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}