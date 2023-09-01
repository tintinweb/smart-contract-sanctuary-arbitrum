pragma solidity 0.6.10;
interface IGlpManager{
    function getPrice(bool _maximise) external view returns (uint256);
}
contract GLPPriceFeed  {
    IGlpManager glpManager;
    constructor(address _glp)public  {
        glpManager = IGlpManager(_glp) ;
    }
    function latestAnswer() public view returns (int256) {
        return  int256(glpManager.getPrice(true));
    }

}