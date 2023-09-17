// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
}

interface IMakePayable {
    function userToContract(address user) external view returns (address);
    function feeExemptAddress() external view returns (address);
}

contract FriendList {
    address public owner;
    address public nftContractAddress;
    address public factoryAddress;
    uint256 public addFriendFee = 10000000000000000; // 0.1 AVAX
    address public makePayableAddress;

   
    constructor(address _nftContractAddress, address _factoryAddress, address _makePayableAddress) {
        owner = msg.sender;
        nftContractAddress = _nftContractAddress;
        factoryAddress = _factoryAddress;
        makePayableAddress = _makePayableAddress; // Initialize makePayableAddress
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

     function getUserPayableContract(address user) public view returns (address) {
        IMakePayable makePayable = IMakePayable(makePayableAddress);
        return makePayable.userToContract(user);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(makePayableAddress).transfer(balance);
    }

    // Function to transfer ownership
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner address cannot be zero");
        owner = newOwner;
    }


    function validateNFTOwnership(uint256 _picId) public view returns (bool) {
        IERC721 nftContract = IERC721(nftContractAddress);
        return (nftContract.ownerOf(_picId) == msg.sender);
    }

    mapping(address => address[]) private friends;

    function addFriend(address _friend) public payable onlyOwner {
        require(_friend != msg.sender, "You cannot add yourself as a friend.");
        require(!isFriend(_friend), "This user is already your friend.");
        require(msg.value >= addFriendFee, "Insufficient fee provided");
        
        address payable targetWallet;
        
        // Check if a custom wallet is defined for the user.
        address customWallet = getUserPayableContract(_friend);
        if (customWallet != address(0)) {
            targetWallet = payable(customWallet);
        } else {
            targetWallet = payable(makePayableAddress);
        }
        
        // Transfer the fee to the target wallet
        targetWallet.transfer(msg.value);

        // Add the friend
        friends[msg.sender].push(_friend);

    }

    function removeFriend(address _friend) public onlyOwner {
        require(isFriend(_friend), "This user is not your friend.");
        address[] storage userFriends = friends[msg.sender];
        for (uint i = 0; i < userFriends.length; i++) {
            if (userFriends[i] == _friend) {
                userFriends[i] = userFriends[userFriends.length - 1];
                userFriends.pop();
                break;
            }
        }
    }

    function isFriend(address _address) public view returns (bool) {
        address[] storage userFriends = friends[msg.sender];
        for (uint i = 0; i < userFriends.length; i++) {
            if (userFriends[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function getFriends() public view returns (address[] memory) {
        return friends[msg.sender];
    }

}

contract FriendListFactory {
    address public owner;
    address public nftContractAddress;
    uint256 public creationFee = 250000000000000000;
    uint256 public zeroNFTFee = 1000000000000000000;
    address public makePayable;

    mapping(address => address) public userToFriendList;

    event FriendListCreated(address indexed user, address friendList);
    

    constructor(address _nftContractAddress) {
        owner = msg.sender;
        nftContractAddress = _nftContractAddress;
        makePayable = 0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function getFeeExemptAddress() public view returns (address) {
        IMakePayable makePayableContract = IMakePayable(makePayable);
        return makePayableContract.feeExemptAddress();
    }

    // Add a new function to get NFT balance of an address
    function getNFTBalance(address user) public view returns (uint256) {
        IERC721 nftContract = IERC721(nftContractAddress);
        return nftContract.balanceOf(user);
    }
    function setCreationFee(uint256 newFee) public onlyOwner {
        creationFee = newFee;
    }
    function setMakePayable(address newMakePayable) public onlyOwner {
        makePayable = newMakePayable;
    }

    receive() external payable {
        payable(makePayable).transfer(msg.value);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(makePayable).transfer(balance);
    }

    // In FriendListFactory contract
    function createUserFriendList() public payable {
        require(userToFriendList[msg.sender] == address(0), "Friends list already created for this user");
        address feeExemptAddr = getFeeExemptAddress();
        uint256 requiredFee = (msg.sender == feeExemptAddr) ? 0 : ((getNFTBalance(msg.sender) == 0) ? zeroNFTFee : creationFee);

        require(msg.value >= requiredFee, "Insufficient payment, please send more Ether");

        FriendList friendList = new FriendList(nftContractAddress, address(this), makePayable); // Pass makePayable here
        friendList.transferOwnership(msg.sender);
        userToFriendList[msg.sender] = address(friendList);

        emit FriendListCreated(msg.sender, address(friendList));
    }
}
