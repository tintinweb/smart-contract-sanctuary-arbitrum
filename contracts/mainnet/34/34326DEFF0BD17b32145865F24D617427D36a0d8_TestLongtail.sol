contract TestLongtail {

    constructor () payable {
    }

    function withdraw() public payable {
        payable(msg.sender).transfer(address(this).balance);
    }
}