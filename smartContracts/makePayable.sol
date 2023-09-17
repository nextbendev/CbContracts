// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
}

// Donation Contract
contract PayableContract {
    address public owner;
    address public factoryAddress;
    bool private locked = false;

    event Received(address indexed sender, uint256 amount);
    event Withdrawn(address indexed owner, uint256 amount);

    constructor(address _owner, address _factoryAddress) {
        owner = _owner;
        factoryAddress = _factoryAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    // Accept donations
    receive() external payable {}
    
    function Donate() public payable {}

    // Owner can withdraw funds
    function withdraw() public onlyOwner noReentrant{
        uint256 amount = address(this).balance;
        uint256 adminFee = (amount * 30) / 1000;   // 3% of the withdrawal amount
        uint256 netAmount = amount - adminFee;

        require(address(this).balance >= amount, "Insufficient balance");

        payable(factoryAddress).transfer(adminFee);  // Send admin fee to the factory
        payable(owner).transfer(netAmount);  // Send the rest to the owner

        emit Withdrawn(owner, netAmount);
    }
     // Function to transfer ownership of the profile
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        owner = newOwner;
    }
  
    // Check contract balance
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

// Factory for deploying donation contracts
contract MakePayable {
    address public factoryOwner;
    address public nftContractAddress;
    uint256 public creationFee = 250000000000000000;
    uint256 public zeroNFTFee = 1000000000000000000;
    address public feeExemptAddress = 0x1A41C605e0502dE0a54035630DA4192A5523E8Ad;

    mapping(address => address) public userToContract;  // Wallet address to contract address
   // Track if a user has deployed a contract

    event PayableContractDeployed(address indexed user, address contractAddress);

    constructor(address _nftContractAddress) {
        factoryOwner = msg.sender;
        nftContractAddress = _nftContractAddress;
    }

    modifier onlyFactoryOwner() {
        require(msg.sender == factoryOwner, "Only the factory owner can call this function");
        _;
    }

    // Function to set the fee-exempt address
    function setFeeExemptAddress(address _feeExemptAddress) public onlyFactoryOwner {
        feeExemptAddress = _feeExemptAddress;
    }
    // Function to set the fee-exempt address
    function setNftCOntract(address _nftContractAddress) public onlyFactoryOwner {
        nftContractAddress = _nftContractAddress;
    }

    function getNFTBalance(address user) public view returns (uint256) {
        IERC721 nftContract = IERC721(nftContractAddress);
        return nftContract.balanceOf(user);
    }

    // Function to change the creation fee
    function setCreationFee(uint256 newFee) public onlyFactoryOwner {
        creationFee = newFee;
    }
    function setZeroNFTFee(uint256 newFee) public onlyFactoryOwner {
        zeroNFTFee = newFee;
    }

    // Deploy a new PayableContract
    function createPayableContract() public payable returns (address) {
        require(userToContract[msg.sender] == address(0), "You have already add make payable function to your wallet");

        uint256 requiredFee = creationFee;
        
       // Check if msg.sender is the fee-exempt address
        if (msg.sender == feeExemptAddress) {
            requiredFee = 0; // Set fee to 0 for the exempt address
        } else {
            // Check NFT balance of the sender
            uint256 nftBalance = getNFTBalance(msg.sender);
            if (nftBalance == 0) {
                requiredFee = zeroNFTFee;  // If NFT balance is 0, set fee to zeroNFTFee
            }
        }

        require(msg.value >= requiredFee, "Insufficient payment");

        PayableContract newContract = new PayableContract(msg.sender, address(this));
        userToContract[msg.sender] = address(newContract);  // Map user to contract
    

        emit PayableContractDeployed(msg.sender, address(newContract));

        return address(newContract);
    }

    // Factory owner can withdraw funds
    function withdraw() public onlyFactoryOwner {
        uint256 balance = address(this).balance;
        payable(factoryOwner).transfer(balance);
    }
     // Function to transfer ownership of the profile
    function transferOwnership(address newOwner) public onlyFactoryOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        factoryOwner = newOwner;
    }
    function donate() public payable {
    }

    receive() external payable {}
}
