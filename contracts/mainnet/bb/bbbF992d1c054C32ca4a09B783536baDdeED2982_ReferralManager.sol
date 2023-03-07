/**
 *Submitted for verification at Arbiscan on 2023-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/*
    Designed, developed by DEntwickler
    @LongToBurn
*/

interface IRefKing {
    function refKingUnlockP()
        external
        view
        returns(uint);

    function refKing()
        external
        view
        returns(address);

    function refKingBalance()
        external
        view
        returns(uint);
}

interface IReferral is IRefKing {
    struct SReferrer {
        address addr;
        uint totalSentA;
    }

    function referrerUnlockA(
        uint referrerBalance_,
        uint lockedA_
    )
        external
        view
        returns(uint);

    function setReturnPWithManager(
        address referrer_,
        uint percent_
    )
        external;

    function returnPOf(
        address referrer_
    )
        external
        view
        returns(uint);


    function referrerOf(
        address child_
    )
        external
        view
        returns(SReferrer memory referrer);

    function totalFromTo(
        address from_,
        address to_
    )
        external
        view
        returns(uint);

    function totalChildren(
        address referrer_
    )
        external
        view
        returns(uint);
}

interface ILockable {
    struct SUnlockedSum {
        uint asReferrer;
        uint asChild;
    }

    function unlockedSumOf(
        address account_
    )
        external
        view
        returns(SUnlockedSum memory);
}

interface IFairLaunchToken is IReferral, ILockable {
}

contract ReferralManager is IFairLaunchToken {
    IFairLaunchToken immutable public fairLaunchToken;

    constructor(
        IFairLaunchToken fairLaunchToken_
    )
    {
        fairLaunchToken = fairLaunchToken_;
    }

    function totalChildren(
        address referrer_
    )
        public
        view
        override
        returns(uint)
    {
        return fairLaunchToken.totalChildren(referrer_);
    }

    function setReturnP(
        uint percent_
    )
        public
    {
        fairLaunchToken.setReturnPWithManager(msg.sender, percent_);
    }

    function unlockedSumOf(
        address account_
    )
        public
        view
        override
        returns(SUnlockedSum memory)
    {
        return fairLaunchToken.unlockedSumOf(account_);
    }

    function returnPOf(
        address referrer_
    )
        public
        view
        override
        returns(uint)
    {
        return fairLaunchToken.returnPOf(referrer_);
    }

    function referrerUnlockA(
        uint referrerBalance_,
        uint lockedA_
    )
        public
        view
        override
        returns(uint)
    {
        return fairLaunchToken.referrerUnlockA(referrerBalance_, lockedA_);
    }

    function referrerOf(
        address child_
    )
        public
        view
        override
        returns(SReferrer memory referrer)
    {
        return fairLaunchToken.referrerOf(child_);
    }

    function totalFromTo(
        address from_,
        address to_
    )
        public
        view
        override
        returns(uint)
    {
        return fairLaunchToken.totalFromTo(from_, to_);
    }

    function refKingUnlockP()
        public
        view
        override
        returns(uint)
    {
        return fairLaunchToken.refKingUnlockP();
    }

    function refKing()
        public
        view
        override
        returns(address)
    {
        return fairLaunchToken.refKing();
    }

    function refKingBalance()
        public
        view
        override
        returns(uint)
    {
        return fairLaunchToken.refKingBalance();
    }

    function setReturnPWithManager(
        address referrer_,
        uint percent_
    )
        public
        override
    {

    }

    function getAccountDetails(
        address account_
    )
        public
        view
        returns(
            SReferrer memory referrerOfAccount,
            SReferrer memory yourReferrer,
            SUnlockedSum memory unlockedSum,
            uint totalChild,
            uint returnP,
            bool isYourChild,
            bool isYourReferrer,
            uint yourTotalSentToAccount
        )
    {
        referrerOfAccount = referrerOf(account_);
        totalChild = totalChildren(account_);
        unlockedSum = unlockedSumOf(account_);
        returnP = returnPOf(account_);
        isYourChild = referrerOfAccount.addr == msg.sender;
        yourReferrer = referrerOf(msg.sender);
        isYourReferrer = yourReferrer.addr == account_;
        yourTotalSentToAccount = totalFromTo(msg.sender, account_);
    }
}