pragma solidity ^0.5.16;

import "./Timer.sol";

contract Auction {

    address internal judgeAddress;
    address internal timerAddress;
    address internal sellerAddress;
    address internal winnerAddress;
    uint winningPrice;

    // TODO: place your code here
    mapping (address => bool) didWinAuction;
    bool internal isAuctionFinalized = false;
    bool internal isThereRefund = false;


    // Modifier checking if winner has been set
    modifier isThereWinner {
        require(winnerAddress != address(0));
        _;
    }

    using address_make_payable for address;

    // constructor
    constructor(address _sellerAddress,
                     address _judgeAddress,
                     address _timerAddress) public {

        judgeAddress = _judgeAddress;
        timerAddress = _timerAddress;
        sellerAddress = _sellerAddress;
        if (sellerAddress == address(0))
          sellerAddress = msg.sender;
    }

    // This is provided for testing
    // You should use this instead of block.number directly
    // You should not modify this function.
    function time() public view returns (uint) {
        if (timerAddress != address(0))
          return Timer(timerAddress).getTime();

        return block.number;
    }

    function getWinner() public view returns (address winner) {
        return winnerAddress;
    }

    function getWinningPrice() public view returns (uint price) {
        return winningPrice;
    }

    // If no judge is specified, anybody can call this.
    // If a judge is specified, then only the judge or winning bidder may call.
    function finalize() public isThereWinner() {
        // TODO: place your code here
        
        if (judgeAddress != address(0)){
            require(msg.sender == judgeAddress || msg.sender == winnerAddress);
        }
        isAuctionFinalized = true;
    }

    // This can ONLY be called by seller or the judge (if a judge exists).
    // Money should only be refunded to the winner.
    function refund() public isThereWinner() {
        // TODO: place your code here
        if (judgeAddress != address(0)){
            require(msg.sender == judgeAddress || msg.sender == sellerAddress);
        } else {
            require(msg.sender == sellerAddress);
        }
        isThereRefund = true;
    }

    // Withdraw funds from the contract.
    // If called, all funds available to the caller should be refunded.
    // This should be the *only* place the contract ever transfers funds out.
    // Ensure that your withdrawal functionality is not vulnerable to
    // re-entrancy or unchecked-spend vulnerabilities.
    function withdraw() public isThereWinner() payable {
        //TODO: place your code here
        if(msg.sender == winnerAddress && isThereRefund){
            address payable winner = winnerAddress.make_payable();
            winner.transfer(winningPrice);
            winningPrice = 0;
        } else if(msg.sender == sellerAddress && isAuctionFinalized){
            address payable seller = sellerAddress.make_payable();
            seller.transfer(winningPrice);
            winningPrice = 0;
        }
    }
}

// Adding a library to make addresses payable
library address_make_payable {
   function make_payable(address x) internal pure returns (address payable) {
       return address(uint160(x));
   }
}
