pragma solidity >=0.8.4;

/**
 * If you are reading this message...
 * You are the one and only, and the loveliest person I’ve ever met.
 * Ever since I met you, I have become stronger, kinder, more passionate,
 * and I hope I make you feel the same way.
 * You have seen the best and the worst of me, and you still love and believe in me.
 * So this is what I propose - let this infinite truth machine be the witness of all the love I promise to give,
 * and the rest of my life spent with you.
 * Will you marry me?
 **/

contract WillYouMarryMe {
    bool engaged = false;

    function yesIdo() public {
        engaged = true;
    }

    function is_engaged() public view returns (bool) {
        return engaged;
    }
}