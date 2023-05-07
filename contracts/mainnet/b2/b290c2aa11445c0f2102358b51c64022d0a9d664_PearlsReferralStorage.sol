/**
 *Submitted for verification at Arbiscan on 2023-05-07
*/

// Sources flattened with hardhat v2.12.7 https://hardhat.org

// File contracts/lib/Ownable.sol

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/periphery/PearlsReferrals.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISocialChef {
    function updateShare(uint256 _pid, address _account) external;
}

contract PearlsReferralStorage is Ownable {

    mapping (address => bool) public isHandler;

    ISocialChef public socialChef;

    mapping (bytes32 => address) public codeOwners;
    mapping (address => bytes32) public pearlProtectorReferralCodes;
    uint256 public totalReferralPoints = 0;
    mapping (address => uint256) public pointsTracked;
    mapping (address => uint256) public pointsByReferral;
    uint256 public totalReferralPointsLP = 0;
    mapping (address => uint256) public pointsTrackedLP;
    mapping (address => uint256) public pointsByReferralLP;

    event SetHandler(address handler, bool isActive);
    event SetTraderReferralCode(address account, bytes32 code);
    event RegisterCode(address account, bytes32 code);
    event SetCodeOwner(address account, address newAccount, bytes32 code);
    event GovSetCodeOwner(bytes32 code, address newAccount);
    event userIncreased(address referrer, address referral, uint256 amount);
    event totalIncreased(uint256 amount);
    event userDecreased(address referrer, address referral, uint256 amount);
    event totalDecreased(uint256 amount);
    event userIncreasedLP(address referrer, address referral, uint256 amount);
    event totalIncreasedLP(uint256 amount);
    event userDecreasedLP(address referrer, address referral, uint256 amount);
    event totalDecreasedLP(uint256 amount);

    modifier onlyHandler() {
        require(isHandler[msg.sender] || msg.sender == address(this), "PearlsReferralStorage: forbidden");
        _;
    }

    constructor (ISocialChef _socialChef) {
        socialChef = _socialChef;
    }

    function setSocialChef(ISocialChef _newSocialChef) external onlyOwner {
        socialChef = _newSocialChef;
    }

    function setHandler(address _handler, bool _isActive) external onlyOwner {
        isHandler[_handler] = _isActive;
        emit SetHandler(_handler, _isActive);
    }

    function setTraderReferralCode(address _account, bytes32 _code) external onlyHandler {
        _setTraderReferralCode(_account, _code);
    }

    //UI
    function setTraderReferralCodeByUser(bytes32 _code) external {
        _setTraderReferralCode(msg.sender, _code);
    }

    function registerCode(bytes32 _code) external {
        require(_code != bytes32(0), "PearlsReferralStorage: invalid _code");
        require(codeOwners[_code] == address(0), "PearlsReferralStorage: code already exists");

        codeOwners[_code] = msg.sender;
        emit RegisterCode(msg.sender, _code);
    }

    function govSetCodeOwner(bytes32 _code, address _newAccount) external onlyOwner {
        require(_code != bytes32(0), "PearlsReferralStorage: invalid _code");

        codeOwners[_code] = _newAccount;
        emit GovSetCodeOwner(_code, _newAccount);
    }

    function pointsToKickbackAndReferrer(uint256 points) internal pure returns (uint256, uint256){
        uint256 kickbackPoints = points / 10; // This gives 10 / 90 split between referral and referrer
        uint256 referrerPoints = points  - kickbackPoints;

        return (kickbackPoints, referrerPoints);
    }

    function kickbackPointsToTotal(uint256 kickbackPoints) internal pure returns (uint256){
        return kickbackPoints * 9;
    }

    function getTraderReferralInfo(address _account) public view returns (bytes32, address) {
        bytes32 code = pearlProtectorReferralCodes[_account];
        address referrer;
        if (code != bytes32(0)) {
            referrer = codeOwners[code];
        }
        return (code, referrer);
    }

    function _setTraderReferralCode(address _account, bytes32 _code) private {
        if(pearlProtectorReferralCodes[_account] != bytes32(0) || codeOwners[_code] == _account){
            // do nothing
        }else{
            pearlProtectorReferralCodes[_account] = _code;
            emit SetTraderReferralCode(_account, _code);
        }
    }
    
    function trackAddPoints(address _referral, uint256 _points) public onlyHandler {
        (, address referrer) = getTraderReferralInfo(_referral);  
        if(referrer == address(0)){
            // do nothing
        }else{
            (uint256 kickbackPoints, uint256 referrerPoints) = pointsToKickbackAndReferrer(_points);

            pointsByReferral[_referral] += _points;

            pointsTracked[_referral] += kickbackPoints;
            pointsTracked[referrer] += referrerPoints;
            
            if(address(socialChef) != address(0)){
                socialChef.updateShare(1, _referral);
                socialChef.updateShare(1, referrer);
            }

            totalReferralPoints += _points;
            
            emit userIncreased(referrer, _referral, referrerPoints);
            emit totalIncreased(_points);
        }
    }

    function trackAddPointsLP(address _referral, uint256 _points) public onlyHandler {
        (, address referrer) = getTraderReferralInfo(_referral);
        if(referrer == address(0)){
            // do nothing
        }else{
            (uint256 kickbackPoints, uint256 referrerPoints) = pointsToKickbackAndReferrer(_points);

            pointsByReferralLP[_referral] += _points;

            pointsTrackedLP[_referral] += kickbackPoints;
            pointsTrackedLP[referrer] += referrerPoints;

            if(address(socialChef) != address(0)){
                socialChef.updateShare(0, _referral);
                socialChef.updateShare(0, referrer);
            }

            totalReferralPointsLP += _points;

            emit userIncreasedLP(referrer, _referral, referrerPoints);
            emit totalIncreasedLP(_points);
        }
    }

    function trackSubPointsLP(address _referral, uint256 _points) public onlyHandler {
        (, address referrer) = getTraderReferralInfo(_referral);
        if(referrer == address(0)){
            // do nothing
        }else{
            if (_points > pointsByReferralLP[_referral]) { // Never substract more than user added to referrer
                _points = pointsByReferralLP[_referral];
                pointsByReferralLP[_referral] = 0;
            } else {
                pointsByReferralLP[_referral] -= _points;
            }

            uint256 kickbackPoints = _points / 10; // This gives 10 / 90 split between referral and referrer
            uint256 referrerPoints = _points  - kickbackPoints;

            // Sub up to referrerPoints from referrer
            if(referrerPoints >= pointsTrackedLP[referrer]){
                emit userDecreasedLP(referrer, _referral, pointsTrackedLP[referrer]);
                pointsTrackedLP[referrer] = 0;
            } else {
                pointsTrackedLP[referrer] -= referrerPoints;
                emit userDecreasedLP(referrer, _referral, referrerPoints);
            }

            // Sub up to kickbackPoints from referral
            if(kickbackPoints >= pointsTrackedLP[_referral]){
                pointsTrackedLP[_referral] = 0;
            } else {
                pointsTrackedLP[_referral] -= kickbackPoints;
            }

            if(address(socialChef) != address(0)){
                socialChef.updateShare(0, referrer);
                socialChef.updateShare(0, _referral);
            }

            if(_points >= totalReferralPointsLP){
                emit totalDecreasedLP(totalReferralPointsLP);
                totalReferralPointsLP = 0;
            }else{
                totalReferralPointsLP -= _points;
                emit totalDecreasedLP(_points);
            }
        }
    }

    function trackSubPoints(address _referral, uint256 _points) public onlyHandler {
        (, address referrer) = getTraderReferralInfo(_referral);
        if(referrer == address(0)){
            // do nothing
        }else{
            if (_points > pointsByReferral[_referral]) { // Never substract more than user added to the system
                _points = pointsByReferral[_referral];
                pointsByReferral[_referral] = 0;
            } else {
                pointsByReferral[_referral] -= _points;
            }

            uint256 kickbackPoints = _points / 10; // This gives 10 / 90 split between referral and referrer
            uint256 referrerPoints = _points  - kickbackPoints;

            // Sub up to referrerPoints from referrer
            if(referrerPoints >= pointsTracked[referrer]){
                emit userDecreased(referrer, _referral, pointsTracked[referrer]);
                pointsTracked[referrer] = 0;
            } else {
                pointsTracked[referrer] -= referrerPoints;
                emit userDecreased(referrer, _referral, referrerPoints);
            }

            // Sub up to kickbackPoints from referral
            if(kickbackPoints >= pointsTracked[_referral]){
                pointsTracked[_referral] = 0;
            } else {
                pointsTracked[_referral] -= kickbackPoints;
            }

            if(address(socialChef) != address(0)){
                socialChef.updateShare(1, referrer);
                socialChef.updateShare(1, _referral);
            }

            if(_points >= totalReferralPoints){
                emit totalDecreased(totalReferralPoints);
                totalReferralPoints = 0;
            }else{
                totalReferralPoints -= _points;
                emit totalDecreased(_points);
            }
        }
    }

    function govSetTraderReferralCode(address _account, bytes32 _code) external onlyOwner {
        bytes32 oldCode = pearlProtectorReferralCodes[_account];

        if (pointsByReferral[_account]>0) {
            uint256 totalPoints = kickbackPointsToTotal(pointsByReferral[_account]);
            this.trackSubPoints(_account, totalPoints);
            pearlProtectorReferralCodes[_account] = _code;
            this.trackAddPoints(_account, totalPoints);
            pearlProtectorReferralCodes[_account] = oldCode;
        }

        if (pointsByReferralLP[_account]>0) {
            uint256 totalPoints = kickbackPointsToTotal(pointsByReferralLP[_account]);
            this.trackSubPointsLP(_account, totalPoints);
            pearlProtectorReferralCodes[_account] = _code;
            this.trackAddPointsLP(_account, totalPoints);
        }

        pearlProtectorReferralCodes[_account] = _code;
        emit SetTraderReferralCode(_account, _code);
    }
}