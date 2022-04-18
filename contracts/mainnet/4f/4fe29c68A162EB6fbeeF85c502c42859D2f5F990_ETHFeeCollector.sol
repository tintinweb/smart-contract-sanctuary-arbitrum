/**
 *Submitted for verification at Arbiscan on 2022-04-18
*/

/*
B.PROTOCOL TERMS OF USE
=======================

THE TERMS OF USE CONTAINED HEREIN (THESE “TERMS”) GOVERN YOUR USE OF B.PROTOCOL, WHICH IS A DECENTRALIZED PROTOCOL ON THE ETHEREUM BLOCKCHAIN (the “PROTOCOL”) THAT enables a backstop liquidity mechanism FOR DECENTRALIZED LENDING PLATFORMS (“DLPs”).  
PLEASE READ THESE TERMS CAREFULLY AT https://github.com/backstop-protocol/Terms-and-Conditions, INCLUDING ALL DISCLAIMERS AND RISK FACTORS, BEFORE USING THE PROTOCOL. BY USING THE PROTOCOL, YOU ARE IRREVOCABLY CONSENTING TO BE BOUND BY THESE TERMS. 
IF YOU DO NOT AGREE TO ALL OF THESE TERMS, DO NOT USE THE PROTOCOL. YOUR RIGHT TO USE THE PROTOCOL IS SUBJECT AND DEPENDENT BY YOUR AGREEMENT TO ALL TERMS AND CONDITIONS SET FORTH HEREIN, WHICH AGREEMENT SHALL BE EVIDENCED BY YOUR USE OF THE PROTOCOL.
Minors Prohibited: The Protocol is not directed to individuals under the age of eighteen (18) or the age of majority in your jurisdiction if the age of majority is greater. If you are under the age of eighteen or the age of majority (if greater), you are not authorized to access or use the Protocol. By using the Protocol, you represent and warrant that you are above such age.

License; No Warranties; Limitation of Liability;
(a) The software underlying the Protocol is licensed for use in accordance with the 3-clause BSD License, which can be accessed here: https://opensource.org/licenses/BSD-3-Clause.
(b) THE PROTOCOL IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS", “WITH ALL FAULTS” and “AS AVAILABLE” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
(c) IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
*/
pragma solidity ^0.5.16;


interface FERC20Like {
    function _withdrawAdminFees(uint withdrawAmount) external returns (uint);
    function totalAdminFees() external view returns(uint);
    function mint() external payable;
    function balanceOf(address a) external returns(uint);
    function transfer(address to, uint amount) external returns(bool);
}

interface BAdminLike {
    function collectFees(address token) external;
}

interface BAMMLike {
    function cBorrow() external returns(FERC20Like);
}

contract ETHFeeCollector {
    address public bamm;
    address public daoFeePool;
    FERC20Like public fToken;
    uint public daoFees;

    event CollectFeeEvent(address amount);

    constructor(address _bamm, address _daoFeePool, uint _daoFees) public {
        bamm = _bamm;
        daoFeePool = _daoFeePool;
        daoFees = _daoFees;
        fToken = BAMMLike(bamm).cBorrow();
    }

    // callable by anyone
    function collectFees(address admin) public {
        fToken._withdrawAdminFees(fToken.totalAdminFees());

        BAdminLike(admin).collectFees(address(0x0));
        fToken.mint.value(address(this).balance)();

        uint fBalance = fToken.balanceOf(address(this));
        uint fee = fBalance * daoFees / 10000;

        if(fee > 0) fToken.transfer(daoFeePool, fee);
        if(fBalance > fee) fToken.transfer(bamm, fBalance - fee);
    }

    function() payable external {}
}