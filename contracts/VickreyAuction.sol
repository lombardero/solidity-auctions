pragma solidity ^0.5.16;

import "./Auction.sol";

contract VickreyAuction is Auction {

    uint public minimumPrice;
    uint public biddingDeadline;
    uint public revealDeadline;
    uint public bidDepositAmount;

    mapping (address => bytes32) internal bidHashes;
    mapping (address => uint) internal revealedValidBids; // Mapping of revealed bids
    mapping (address => uint) internal refunds; // Mapping of refunds
    address internal currentWinner;
    uint internal highestBid;
    uint internal secondHighestBid;

    // Defining modifiers to check timings
    modifier isAuctionOver() {
        require(time() < biddingDeadline);
        _;
    }

    modifier isItRevealTime() {
        require(time() >= biddingDeadline);
        require(time() < revealDeadline);
        _;
    }

    modifier isRevealTimeOver() {
        require(time() >= revealDeadline);
        _;
    }

    // constructor
    constructor(address _sellerAddress,
                            address _judgeAddress,
                            address _timerAddress,
                            uint _minimumPrice,
                            uint _biddingPeriod,
                            uint _revealPeriod,
                            uint _bidDepositAmount) public
             Auction (_sellerAddress, _judgeAddress, _timerAddress) {

        minimumPrice = _minimumPrice;
        bidDepositAmount = _bidDepositAmount;
        biddingDeadline = time() + _biddingPeriod;
        revealDeadline = time() + _biddingPeriod + _revealPeriod;

        // TODO: place your code here
        // Initializing highest and 2nd highest bid
        highestBid = minimumPrice;
        secondHighestBid = minimumPrice;
    }

    // Record the player's bid commitment
    // Make sure exactly bidDepositAmount is provided (for new bids)
    // Bidders can update their previous bid for free if desired.
    // Only allow commitments before biddingDeadline
    function commitBid(bytes32 bidCommitment) public payable isAuctionOver() {
        // TODO: place your code here

        // Check if bidder has sent valid deposit (if already submitted, we are nice and force it to be zero)
        if (bidHashes[msg.sender] == bytes32(0)){
            require(msg.value == bidDepositAmount, "Wrong deposit value sent!");
        } else {
            require(msg.value == 0, "Wrong deposit value sent!");
        }

        // Recording the valid commitment
        bidHashes[msg.sender] = bidCommitment;
    }

    // Check that the bid (msg.value) matches the commitment.
    // If the bid is correctly opened, the bidder can withdraw their deposit.
    function revealBid(bytes32 nonce) public payable isItRevealTime() returns(bool isHighestBidder) {
        // TODO: place your code here

        // Checking if the nonce and the amount match the commit previously sent
        bytes32 signature = keccak256(abi.encodePacked(bytes32(msg.value),nonce));
        require(signature == bidHashes[msg.sender]);

        // Updating data so that withdraw can be claimed
        refunds[msg.sender] = bidDepositAmount;
        revealedValidBids[msg.sender] = msg.value;

        // Updating internally highest bidders (we keep the info of the top 2 bids)
        if (msg.value >= highestBid){
            secondHighestBid = highestBid;
            highestBid = msg.value;
            currentWinner = msg.sender;
            isHighestBidder = true; // Currently, he is the highest bidder
        } else if (msg.value >= secondHighestBid){
            secondHighestBid = msg.value;
            isHighestBidder = false; // Someone already outbidded 
        } else {
            isHighestBidder = false; // Not even top 2
        }
    }

    // Need to override the default implementation
    function getWinner() public view isRevealTimeOver() returns (address winner){
        // TODO: place your code here

        return currentWinner;
    }

    // finalize() must be extended here to provide a refund to the winner
    // based on the final sale price (the second highest bid, or reserve price).
    function finalize() public {
        // TODO: place your code here

        // Setting up winner, allowing him to get the differene between his bid
        // and the next one when he calls withdraw
        winnerAddress = currentWinner;
        refunds[winnerAddress] += highestBid-secondHighestBid;

        // call the general finalize() logic
        super.finalize();
    }
    // Reimplementing "withdraw" to refund all addresses
    function withdraw() public payable {
        require(refunds[msg.sender] != 0);

        // If withdraw called by a bidder, he gets back his bid and his deposit
        if (msg.sender != winnerAddress){
            address payable withdrawer = msg.sender;
            withdrawer.transfer(refunds[msg.sender]+revealedValidBids[msg.sender]);
            refunds[msg.sender] = 0;
        
        // If withdraw called by the winner, he gets back his deposit + difference with second price
        } else {
            address payable withdrawer = msg.sender;
            withdrawer.transfer(refunds[msg.sender]);
            refunds[msg.sender] = 0;
        }
    }

}

