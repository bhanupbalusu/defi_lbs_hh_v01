//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract LendingModule is ChainlinkClient {
    // get Chainlink object
    using Chainlink for Chainlink.Request;

    // Chainlink specifics
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    // Api urls to request for credit score
    // string[] private creditScoreApiUrls = [
    //     "https://run.mocky.io/v3/5420a00a-84fe-4b24-8388-c8231562286d",
    //     "https://run.mocky.io/v3/74f8efff-596a-4c88-908b-aa76d49f49f6",
    //     "https://run.mocky.io/v3/f9409202-276e-4835-9c68-8064db4c5298"
    // ];

    // Map the user addresses with their balance
    mapping(address => uint256) balances;

    // calculate interest and AcrueInterest
    // we need to keep track of deposit Timestamps when the user does his last deposit
    mapping(address => uint256) depositTimestamps;

    // mapping of requestId to user address for tracking oracle response
    mapping(bytes32 => address) private requestToUser;

    // Store the users credit score
    mapping(address => uint256) private userCreditScores;

    // store users risk score
    mapping(address => uint256) private usersRiskScores;

    // Declare annual interest rate, representaed as a percentage
    uint256 public annualInterestRate;

    // When ever someone deposit ether amount Deposit event should get triggered
    event Deposit(address indexed user, uint256 amount);

    // When ever an interest is paid to the user InterestPaid event should get triggered
    event InterestPaid(address indexed user, uint256 interest);

    // event emitted when the loan is requested
    event LoanRequested(address indexed user, uint256 amount);

    // event emitted when a credit score is recieved from the oracle
    event CreditScoreRecieved(address indexed user, uint256 creditScore);

    // event emitted when riskScore is assessed
    event RiskScoreCalculated(address indexed user, uint256 riskScore);

    // constructor to initial the contact with a given annual interest rate
    constructor(
        uint256 _annualInterestRate,
        address _oracle,
        bytes32 _jobId,
        uint256 _fee
    ) {
        annualInterestRate = _annualInterestRate;
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee; // Typically 0.1 link
    }

    // deposit function should allow users to deposit the ether amount
    function deposit() external payable {
        // check if deposit amount is greater than zero
        require(msg.value > 0, "Deposit amount must be greater than zero");

        // if deposit amount is greater than zero add the amount to the balance
        balances[msg.sender] += msg.value;

        // store the deposited timestamp information
        depositTimestamps[msg.sender] = block.timestamp;

        // now emit the Deposit event
        emit Deposit(msg.sender, msg.value);
    }

    // function to check balance of the user which takes users address and returns the balance value for that address
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    // function to calculate interest. It takes users address and returns the interest amount accumulated
    function calculateInterest(address user) public view returns (uint256) {
        // get the numeber of seconds between current timestamp - last deposited timestamp
        uint256 depositTimeInSeconds = block.timestamp -
            depositTimestamps[user];

        // get the interest rate per second
        uint256 interestRatePerSecond = (annualInterestRate * 1e18) /
            (365 days);

        // apply logic to calculate interest. balance amount * interestRatePerSecond * number of seconds / 100
        return
            (balances[user] * interestRatePerSecond * depositTimeInSeconds) /
            1e18 /
            100;
    }

    // function to acrue interest. It updates the balance adding acrued interest amount and emit InterestPaid event
    function acrueInterest() external {
        // call calculateInterest function to get the interest amount accumulated
        uint256 interestAccumulated = calculateInterest(msg.sender);

        // check if interestAccumulated is greater than zero
        require(interestAccumulated > 0, "No interest to acrue");

        // add that amount to the balance
        balances[msg.sender] += interestAccumulated;

        // update the depositTimeStamps value
        depositTimestamps[msg.sender] = block.timestamp;

        // emit InterestPaid event
        emit InterestPaid(msg.sender, interestAccumulated);
    }

    // function to request for loan. It takes loan amount and emits loan requested event
    function requestLoan(uint256 loanAmount) external {
        require(loanAmount > 0, "Loan amount must be greater than zero");
        // bytes32 requestID = requestCreditScore(msg.sender);
        // bytes32 requestID = requestCreditScore();
        // requestToUser[requestID] = msg.sender;
        emit LoanRequested(msg.sender, loanAmount);
    }

    // function to request credit score using chainlink
    function requestCreditScore() public {
        // build chainlink request
        Chainlink.Request memory request = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        // // randomise the selection of url
        // string memory selectedUrl = creditScoreApiUrls[
        //     uint256(uint160(user)) % creditScoreApiUrls.length
        // ];

        // add URL and path to the request
        request.add(
            "get",
            "https://run.mocky.io/v3/5420a00a-84fe-4b24-8388-c8231562286d"
        );
        request.add("path", "creditScore");

        // send the request to the chainlink oracle
        sendChainlinkRequestTo(oracle, request, fee);
    }

    // fulfill function is called by chainlink oracle when it retrieves the requested data.
    // we can call risk assesment function inside this fulfill function
    function fulfill(
        bytes32 _requestId,
        uint256 _creditScore
    ) public recordChainlinkFulfillment(_requestId) {
        address user = requestToUser[_requestId];
        userCreditScores[user] = _creditScore;
        emit CreditScoreRecieved(user, _creditScore);
        // get the riskScore
        uint256 riskScore = assessRisk(user, _creditScore);
        emit RiskScoreCalculated(user, riskScore);
    }

    // function to get user credit score
    function getUserCreditScore(address user) public view returns (uint256) {
        return userCreditScores[user];
    }

    // function to asses risk
    function assessRisk(
        address user,
        uint256 creditScore
    ) internal returns (uint256) {
        uint256 riskScore;
        if (creditScore > 700) {
            riskScore = 1;
        } else if (creditScore > 600) {
            riskScore = 2;
        } else {
            riskScore = 3;
        }

        usersRiskScores[user] = riskScore;
        return riskScore;
    }
}
