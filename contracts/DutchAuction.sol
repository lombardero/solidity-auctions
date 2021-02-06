pragma solidity ^0.5.16;

import "./Auction.sol";

contract DutchAuction is Auction {

    uint public initialPrice;
    uint public biddingPeriod;
    uint public offerPriceDecrement;

    uint internal initialBlock;
    uint internal lastBlockAllowed;
    bool internal hasBeenClaimed;

    event Debug(address _sender, uint _value, uint _currentPrice);
    event Debug2(uint _difference, uint _time, uint _decrement);


    // constructor
    constructor(address _sellerAddress,
                          address _judgeAddress,
                          address _timerAddress,
                          uint _initialPrice,
                          uint _biddingPeriod,
                          uint _offerPriceDecrement) public
             Auction (_sellerAddress, _judgeAddress, _timerAddress) {

        initialPrice = _initialPrice;
        biddingPeriod = _biddingPeriod;
        offerPriceDecrement = _offerPriceDecrement;


        // Give the contract Judge powers
        judgeAddress = address(this);

        // Compute initial and max time allowed
        lastBlockAllowed = time() + biddingPeriod;
        initialBlock = time();
    }

    function bid() public payable{

        // Checking current price
        uint currentPrice = initialPrice - (time() - initialBlock) * offerPriceDecrement;

        // Checking that bid is valid, and there is no winner already
        require(msg.value >= currentPrice && time() < lastBlockAllowed);
        require(winnerAddress == address(0));
        uint difference = msg.value - currentPrice;

        // Make the refund possible
        winnerAddress = msg.sender;
        winningPrice = difference;
        this.refund();
    }
}
