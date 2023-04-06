/**
 *Submitted for verification at Arbiscan on 2023-04-06
*/

//,..(                                               
//...)\ )       )                            (    )  
//..(()/(    ( /((           (   (    )   (  )\( /(  
// ../(_))(  )\())\  (   (   )\  )\( /(  ))\((_)\()) 
//..(_))  )\(_))((_) )\  )\ |(_)((_)(_))/((_)_(_))/  
//..| _ \((_) |_ (_)((_)_(_/( \ / ((_)_(_))(| | |_   
//..|  _/ _ \  _|| / _ \ ' \)) V // _` | || | |  _|  
//..|_| \___/\__||_\___/_||_| \_/ \__,_|\_,_|_|\__|  
//                  TimeLock

//            https://Poison.Finance

pragma solidity ^0.8.18;

interface IPotionVaultAdmin {
    function setAdmin(address _admin) external;

    function setCanMint(bool _canMint) external;

    function setCollector(address _collector) external;

    function setStartTime(uint256 _startTime) external;

    function setSynCanMint(bool _canMint, uint256 id) external;

    function setStableTokenCanMint(bool _canMint, uint256 id) external;

    function setSynOracle(address _oracle, uint256 id) external;

    function addStableToken(
        address _stableToken,
        uint256 _underlyingContractDecimals,
        bool _canMint
    ) external;

    function addSynToken(
        address _synToken,
        address _oracle,
        bool _canMint,
        bool _nasdaqTimer,
        uint256 _minCratio
    ) external;
}

contract PotionVaultTimeLock {
    struct TokenInfo {
        address stableToken;
        uint256 underlyingContractDecimals;
        bool canMint;
        uint256 delay;
    }

    struct SynInfo {
        address synToken;
        address oracle;
        bool canMint;
        bool nasdaqTimer;
        uint256 minCratio;
        uint256 delay;
    }

    struct SynCanMintInfo {
        bool canMint;
        uint256 id;
        uint256 delay;
    }

    struct StableTokenCanMintInfo {
        bool canMint;
        uint256 id;
        uint256 delay;
    }

    struct SynOracleInfo {
        address oracle;
        uint256 id;
        uint256 delay;
    }

    IPotionVaultAdmin public PotionVault;

    address public admin;
    address public pendingAdmin;
    address public timeLock;
    address public collector;

    bool public canMint;

    uint256 public startTime;

    TokenInfo[] public tokenInfo;
    SynInfo[] public synInfo;

    SynCanMintInfo[] public synCanMintInfo;
    StableTokenCanMintInfo[] public stableTokenCanMintInfo;
    SynOracleInfo[] public synOracleInfo;

    mapping(uint256 => uint256) public delay;

    constructor(address _PotionVault) {
        PotionVault = IPotionVaultAdmin(_PotionVault);
        admin = msg.sender;
    }

    function setAdmin(address _admin) external {
        require(msg.sender == admin, "Admin only");
        pendingAdmin = _admin;
        delay[0] = block.timestamp + 24 hours;
    }

    function applyAdmin() external {
        require(msg.sender == admin, "Admin only");
        require(block.timestamp >= delay[0]);
        admin = pendingAdmin;
    }

    function setTimeLock(address _timeLock) external {
        require(msg.sender == admin, "Admin only");
        timeLock = _timeLock;
        delay[1] = block.timestamp + 24 hours;
    }

    function applyTimeLock() external {
        require(msg.sender == admin, "Admin only");
        require(block.timestamp >= delay[1]);
        PotionVault.setAdmin(timeLock);
    }

    function setCanMint(bool _canMint) external {
        require(msg.sender == admin, "Admin only");
        delay[2] = block.timestamp + 10 minutes;
        canMint = _canMint;
    }

    function applyCanMint() external {
        require(msg.sender == admin, "Admin only");
        require(block.timestamp >= delay[2]);
        PotionVault.setCanMint(canMint);
    }

    function setCollector(address _collector) external {
        require(msg.sender == admin, "Admin only");
        delay[3] = block.timestamp + 24 hours;
        collector = _collector;
    }

    function applyCollector() external {
        require(msg.sender == admin, "Admin only");
        require(block.timestamp >= delay[3]);
        PotionVault.setCollector(collector);
    }

    function setStartTime(uint256 _startTime) external {
        require(msg.sender == admin, "Admin only");
        delay[4] = block.timestamp + 24 hours;
        startTime = _startTime;
    }

    function applyStartTime() external {
        require(msg.sender == admin, "Admin only");
        require(block.timestamp >= delay[4]);
        PotionVault.setStartTime(startTime);
    }

    function setSynCanMint(bool _canMint, uint256 _id) external {
        require(msg.sender == admin, "Admin only");
        synCanMintInfo.push(
            SynCanMintInfo({
                canMint: _canMint,
                id: _id,
                delay: block.timestamp + 30 minutes
            })
        );
    }

    function applySynCanMint() external {
        require(msg.sender == admin, "Admin only");
        SynCanMintInfo storage synCanMint = synCanMintInfo[
            synCanMintInfo.length - 1
        ];
        require(block.timestamp >= synCanMint.delay);
        PotionVault.setSynCanMint(synCanMint.canMint, synCanMint.id);
    }

    function setStableTokenCanMint(bool _canMint, uint256 _id) external {
        require(msg.sender == admin, "Admin only");
        stableTokenCanMintInfo.push(
            StableTokenCanMintInfo({
                canMint: _canMint,
                id: _id,
                delay: block.timestamp + 30 minutes
            })
        );
    }

    function applyStableTokenCanMint() external {
        require(msg.sender == admin, "Admin only");
        StableTokenCanMintInfo
            storage stableTokenCanMint = stableTokenCanMintInfo[
                synCanMintInfo.length - 1
            ];
        require(block.timestamp >= stableTokenCanMint.delay);
        PotionVault.setStableTokenCanMint(
            stableTokenCanMint.canMint,
            stableTokenCanMint.id
        );
    }

    function setSynOracle(address _oracle, uint256 _id) external {
        require(msg.sender == admin, "Admin only");
        synOracleInfo.push(
            SynOracleInfo({
                oracle: _oracle,
                id: _id,
                delay: block.timestamp + 24 hours
            })
        );
    }

    function applySynOracle() external {
        require(msg.sender == admin, "Admin only");
        SynOracleInfo storage synOracle = synOracleInfo[
            synCanMintInfo.length - 1
        ];
        require(block.timestamp >= synOracle.delay);
        PotionVault.setSynOracle(synOracle.oracle, synOracle.id);
    }

    function addStableToken(
        address _stableToken,
        uint256 _underlyingContractDecimals,
        bool _canMint
    ) external {
        require(msg.sender == admin, "Admin only");
        tokenInfo.push(
            TokenInfo({
                stableToken: _stableToken,
                underlyingContractDecimals: _underlyingContractDecimals,
                canMint: _canMint,
                delay: block.timestamp + 24 hours
            })
        );
    }

    function applyStableToken() external {
        require(msg.sender == admin, "Admin only");
        TokenInfo storage token = tokenInfo[tokenInfo.length - 1];
        require(block.timestamp >= token.delay);
        PotionVault.addStableToken(
            token.stableToken,
            token.underlyingContractDecimals,
            token.canMint
        );
    }

    function addSynToken(
        address _synToken,
        address _oracle,
        bool _canMint,
        bool _nasdaqTimer,
        uint256 _minCratio
    ) external {
        require(msg.sender == admin, "Admin only");
        synInfo.push(
            SynInfo({
                synToken: _synToken,
                oracle: _oracle,
                canMint: _canMint,
                nasdaqTimer: _nasdaqTimer,
                minCratio: _minCratio,
                delay: block.timestamp + 24 hours
            })
        );
    }

    function applySynToken() external {
        require(msg.sender == admin, "Admin only");
        SynInfo storage syn = synInfo[synInfo.length - 1];
        require(block.timestamp >= syn.delay);
        PotionVault.addSynToken(
            syn.synToken,
            syn.oracle,
            syn.canMint,
            syn.nasdaqTimer,
            syn.minCratio
        );
    }
}