//This contract mocks the necessary functions for the GLPOracle for testing purposes only

pragma solidity ^0.8.10;

contract MockGLP {

    address public GLP;

    address public GLPManager;
    

    //address public admin = msg.sender;

    function setGLPAddress (address _GLP) public returns (address) {
        GLP = _GLP;
        return GLP;
    }

    function setGLPManager (address _GLPManager) public returns (address) {
        GLPManager = _GLPManager;
        return GLPManager;
    }

    function getAum(bool maximise) public view returns (uint256) {

        uint256 aum;

        if(maximise == false) {
            aum = 289751348156355989840954443190634393128;
        }
        else {
            aum = 0;
        }
        return aum;
    }

    function totalSupply() public view returns (uint256) {
        uint256 totalSupply;
        totalSupply = 320524293832658104459556845;
        return totalSupply;
    }
}