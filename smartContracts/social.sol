// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface for ERC721 tokens
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
    function feeExemptAddress() external view returns (address);
}

// Contract to hold individual social profiles
contract SocialProfile {
    //string public fields for user profile
    string public field1;
    string public field2;
    string public field3;
    string public field4;
    string public field5;
    string public field6;
    string public field7;
    string public field8;
    string public field9;
    string public username;
    string public socialLink1;
    string public socialLink2;
    string public socialLink3;
    string public email;
    uint256 public picId; // NFT ID for profile picture
    address public owner;
    address public nftContractAddress;
    address  public factoryAddress;
    address payable public makePayable;
    SocialsFactory public socialsFactory;
     
    // Constructor
    constructor(
        address _nftContractAddress, 
        address payable _factoryAddress, 
        address _owner,
        address payable _makePayable 
    ) {
        require(_factoryAddress != address(0), "Factory address must be valid");
        require(_makePayable != address(0), "makePayable address must be valid"); 
        owner = _owner;
        nftContractAddress = _nftContractAddress;
        factoryAddress = _factoryAddress;
        makePayable = _makePayable; // <- Initialize makePayable
        socialsFactory = SocialsFactory(_factoryAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
 
    function withdraw() public  {
        uint256 balance = address(this).balance;
        payable(makePayable).transfer(balance);
    }
       // Forward the fee to the factory contract
    modifier forwardFee() {
        address payable feeExemptAddr = payable(IERC721(makePayable).feeExemptAddress());

        if (msg.sender == feeExemptAddr) {
           payable(makePayable).transfer(msg.value);
        } else {
            if (getNFTBalance(msg.sender) >= 1) {
                require(msg.value >= socialsFactory.operationFee(), "Insufficient operation fee");
                payable(makePayable).transfer(msg.value);

            } else {
                require(msg.value >= socialsFactory.zeroNFTFee(), "Insufficient operation fee");
                payable(makePayable).transfer(msg.value);
            }
        }
        _;
    }

    // Functions to set individual fields of the profile. Only the owner can set these.
    function setField1(string memory _field1) public onlyOwner payable  forwardFee {
        field1 = _field1;

    }

    function setField2(string memory _field2) public onlyOwner payable forwardFee  {
      
        field2 = _field2;

    }

    function setField3(string memory _field3) public onlyOwner payable  forwardFee {
     
        field3 = _field3;

    }

    function setField4(string memory _field4) public onlyOwner payable  forwardFee{
        field4 = _field4;
    }

    function setField5(string memory _field5) public onlyOwner payable  forwardFee{
        field5 = _field5;
    }

    function setField6(string memory _field6) public onlyOwner payable  forwardFee{
        field6 = _field6;
    }

    function setField7(string memory _field7) public onlyOwner payable  forwardFee{
        field7 = _field7;
    }

    function setField8(string memory _field8) public onlyOwner payable  forwardFee{
        field8 = _field8;
    }

    function setField9(string memory _field9) public onlyOwner payable  forwardFee{
        field9 = _field9;
    }

    function setUsername(string memory _username) public onlyOwner payable  forwardFee{
        username = _username;
    }
      // Function to set the NFT ID as the profile picture
    function setPicId(uint256 _picId) public onlyOwner payable forwardFee {
        require(validateNFTOwnership(_picId), "You must own the NFT to set this ID");
        picId = _picId;
    }
    function setSocialLink1(string memory _socialLink1) public onlyOwner payable  forwardFee{
        socialLink1 = _socialLink1;
    }
    function setSocialLink2(string memory _socialLink2) public onlyOwner payable  forwardFee{
        socialLink2 = _socialLink2;
    }
    function setSocialLink3(string memory _socialLink3) public onlyOwner payable  forwardFee{
        socialLink3 = _socialLink3;
    }
    function setEmail(string memory _email) public onlyOwner payable  forwardFee{
        email = _email;
    }

    // Function to validate ownership of an NFT for the profile picture
    function validateNFTOwnership(uint256 _picId) public view returns (bool) {
        IERC721 nftContract = IERC721(nftContractAddress);
        return (nftContract.ownerOf(_picId) == msg.sender);
    }
    // Function to get the NFT balance of a user
    function getNFTBalance(address user) public view returns (uint256) {
        IERC721 nftContract = IERC721(nftContractAddress);
        return nftContract.balanceOf(user);
    }

  

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        require(newOwner != owner, "New owner must be different from the current owner");
        owner = newOwner;
    }

}

// Factory contract to deploy SocialProfile contracts
contract SocialsFactory {
    address public owner;
    address public nftContractAddress;
    uint256 public creationFee = 250000000000000000; // 0.25 AVAX
    uint256 public zeroNFTFee = 1000000000000000000; // 1 AVAX
    uint256 public operationFee = 10000000000000000;
    uint256 public zeroNFTOperationFee = 2000000000000000;
    address public makePayable;

    // Mapping to link users to their respective social profiles
    mapping(address => address) public userToProfile;
   

    event SocialProfileDeployed(address indexed owner, address contractAddress);

    constructor(address _nftContractAddress) {
        owner = msg.sender;
        nftContractAddress = _nftContractAddress;
        makePayable = 0xf8e81D47203A594245E36C48e151709F0C19fBe8;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }


    // Function to get the NFT balance of a user
    function getNFTBalance(address user) public view returns (uint256) {
        IERC721 nftContract = IERC721(nftContractAddress);
        return nftContract.balanceOf(user);
    }
    function getFeeExemptAddress() public view returns (address) {
        IERC721 exemptAddress = IERC721(makePayable);
        return exemptAddress.feeExemptAddress();
    }

    // Function to set the creation fee for new profiles
    function setCreationFee(uint256 newFee) public onlyOwner {
        creationFee = newFee;
    }
    function setOperationFee(uint256 newFee) public onlyOwner {
        operationFee = newFee;
    }

    function setMakePayable(address newMakePayable) public onlyOwner {
        makePayable = newMakePayable;
    }

    function SetNftContractAddress(address nftContract) public onlyOwner {
        require(nftContract != address(0), "New NFT contract cannot be zero address");
        nftContractAddress = nftContract;
    }

    // Fallback function to receive payments
    receive() external payable {}
   
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function createSocialProfile() public payable returns (address) {
        require(userToProfile[msg.sender] == address(0), "You have already created a profile");

        // Check if the caller is a fee-exempt address
        address feeExemptAddr = getFeeExemptAddress();
        
        uint256 requiredFee;
        if (msg.sender == feeExemptAddr) {
            requiredFee = 0;
        } else {
            if (getNFTBalance(msg.sender) >= 1) {
                requiredFee = creationFee;
            } else {
                requiredFee = zeroNFTFee;
            }
        }
    
        require(msg.value >= requiredFee, "Insufficient payment");

        SocialProfile newProfile = new SocialProfile(nftContractAddress, payable(address(this)), msg.sender, payable(makePayable));

        userToProfile[msg.sender] = address(newProfile);

        emit SocialProfileDeployed(msg.sender, address(newProfile));
        return address(newProfile);
    }


    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        payable(owner).transfer(address(this).balance);
    }

    // Function to transfer ownership of the profile
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        owner = newOwner;
    }

}

