//this contract mocks the necessary functions behind plvGLP and is for testing purposes ONLY

pragma solidity ^0.8.10;

contract MockPlvGLP {

    address plvGLP;


    function setPlvGLPAddress (address _plvGLP) public returns (address) {
        plvGLP = _plvGLP;
        return plvGLP;
    }

    function totalAssets() public view returns (uint256) {
        uint256 totalAssets;
        totalAssets = 4385690448959168297133346;
        return totalAssets;
    }

    function totalSupply() public view returns (uint256) {
        uint256 totalSupply;
        totalSupply = 4335445707657153052302414;
        return totalSupply;
    }
}