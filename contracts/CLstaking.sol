// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


interface Mintable {
   function mint(address to, uint256 amount) external;
   function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
}

contract CyberlionStaking is Ownable, AccessControl {
    bytes32 public ADMIN_ROLE = keccak256("ADMIN");
    using SafeMath for uint256;

    using Address for address;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    uint256 constant SECONDS_PER_DAY = 10*60;
    address rewardsTokenAddress;
    // struct stakedToken {
    //     uint id;
    //     uint256 timeStaked;
    // }
    // struct UserInfo {
    //     mapping(uint => stakedToken) stakedTokens;
    //     uint256 amountStaked;
    // }
    
    struct CollectionInfo {
        address collectionAddress;
        uint256 rewardPerDay;
        uint256 totalAmountStaked;
    }

    struct CollectionData {
        mapping(address => uint[]) userToStakedTokenIDs;
        mapping(uint => address) tokenIDToOwner;
        mapping(uint => uint) tokenIDToStakedTime;
    }

    // mapping(address => UserInfo) public userInfo;
    mapping(address => mapping(address => uint[])) addressToStakedTokens;
    mapping(address => mapping(uint => address)) contractTokenIdToOwner;
    mapping(address => mapping(uint => uint)) contractTokenIdToStakedTimestamp;

    mapping(address => CollectionData) collectionData;

    CollectionInfo[] public collectionInfo;

    constructor(address _rewardsToken) {
        rewardsTokenAddress = _rewardsToken;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    function setAdminRole(address admin) public onlyRole(DEFAULT_ADMIN_ROLE){
        _setupRole(ADMIN_ROLE, admin);
    }

    function stake(uint256 _collectionID, uint256 _tokenID) external {
        _stake(msg.sender, _collectionID, _tokenID);
    }

    function _stake(
        address _userAddress,
        uint256 _collectionID,
        uint256 _tokenID
    ) internal {
        // UserInfo storage user = userInfo[_userAddress];
        CollectionInfo storage collection = collectionInfo[_collectionID];
        
        // Track original owner of token about to be staked
        contractTokenIdToOwner[collection.collectionAddress][_tokenID] = _userAddress;
        // Track time token was staked
        contractTokenIdToStakedTimestamp[collection.collectionAddress][_tokenID] = block.timestamp;
        // Add to the list of tokens staked for this particular owner and contract
        addressToStakedTokens[collection.collectionAddress][_userAddress].push(_tokenID);

        collection.totalAmountStaked += 1;

        // transfer token into the custody of the contract
        IERC721(collection.collectionAddress).transferFrom(_userAddress, address(this), _tokenID);
    }

    function batchStake(uint256 _collectionID, uint256[] memory _tokenIDs) external {
        for (uint256 i = 0; i < _tokenIDs.length; ++i) {
            _stake(msg.sender, _collectionID, _tokenIDs[i]);
        }
    }

    function batchUnstake(uint256 _collectionID, uint256[] memory _tokenIDs) external {
        for (uint256 i = 0; i < _tokenIDs.length; ++i) {
            _unstake(msg.sender, _collectionID, _tokenIDs[i]);
        }
    }

    function unstake(uint256 _collectionID, uint256 _tokenID) external {
        _unstake(msg.sender, _collectionID, _tokenID);
    }

    function mintTest() public onlyRole(ADMIN_ROLE) {
        Mintable(rewardsTokenAddress).mint(msg.sender,1);
    }

    function _unstake(
        address _userAddress,
        uint256 _collectionID,
        uint256 _tokenID
    ) internal {
        //UserInfo storage user = userInfo[_userAddress];
        CollectionInfo storage collection = collectionInfo[_collectionID];

        // require(
        //     addressToStakedTokens[collection.collectionAddress][_tokenID] == _userAddress,
        //     "sender doesn't owns this token"
        // );

        // review
        // require(addressToStakedTokens[collection.collectionAddress][_tokenID].contains(_tokenID), "token is not staked");

        _claimReward(msg.sender, _collectionID, _tokenID);

        _removeElement(addressToStakedTokens[collection.collectionAddress][_userAddress], _tokenID);
        delete contractTokenIdToOwner[collection.collectionAddress][_tokenID];
        delete contractTokenIdToStakedTimestamp[collection.collectionAddress][_tokenID];

        // user.timeStaked[_tokenID].timeStaked = block.timestamp; // Why
        // user.amountStaked -= 1;
        collection.totalAmountStaked -= 1;
        // if (user.amountStaked == 0) {
        //     delete userInfo[_userAddress];
        // }
        IERC721(collection.collectionAddress).transferFrom(address(this), _userAddress, _tokenID);
        
    }

    function totalClaimableReward(address _userAddress, uint256 _collectionID) public view returns(uint256) {
        uint payableAmount = 0;
        address collectionAddress = collectionInfo[_collectionID].collectionAddress;
        for (uint256 i; i < addressToStakedTokens[collectionAddress][_userAddress].length; i++) {
            uint _tokenId = addressToStakedTokens[collectionAddress][_userAddress][i];
            payableAmount += claimableReward(_userAddress, _collectionID, _tokenId);
        }
        return payableAmount;
    }

    function claimableReward(address _userAddress, uint256 _collectionID,uint256 _tokenID) public view returns(uint256) {
        CollectionInfo storage collection = collectionInfo[_collectionID];
         // is there ever tokenID 0? I don't think so...
        if(!contractTokenIdToOwner[collection.collectionAddress][_tokenID])
          return 0;
        uint timeStaked = contractTokenIdToStakedTimestamp[collection.collectionAddress][_tokenID];
        uint256 payableAmount = (block.timestamp - timeStaked)
            .div(SECONDS_PER_DAY)
            .mul(collection.rewardPerDay);
        return payableAmount;
    }

    function _claimReward(address _userAddress, uint256 _collectionID,uint256 _tokenID) internal {
        uint256 payableAmount = claimableReward(_userAddress, _collectionID,_tokenID);
        Mintable(rewardsTokenAddress).mint(msg.sender,payableAmount);
    }

    function setCollection(address _collectionAddress, uint256 _rewardPerDay) public onlyRole(ADMIN_ROLE) {

        collectionInfo.push(
            CollectionInfo({collectionAddress: _collectionAddress, rewardPerDay: _rewardPerDay, totalAmountStaked: 0})
        );
    }

    function updateCollection(
        uint256 _collectionID,
        address _collectionAddress,
        uint256 _rewardPerDay
    ) public onlyRole(ADMIN_ROLE)  {
        CollectionInfo storage collection = collectionInfo[_collectionID];
        collection.collectionAddress = _collectionAddress;
        collection.rewardPerDay = _rewardPerDay;
    }

    // function getUserInformation(address _userAddress, address _collectionAddr, uint256 _tokenID) external view returns (uint256[] memory, uint256[] memory) {
    //     uint256[] memory _tokenIDs = addressToStakedTokens[_collectionAddr][_userAddress];
    //     uint256[] memory _timestamps;
    //     for (uint256 i; i < _tokenIDs.length; i++) {
    //         _timestamps[i] = contractTokenIdToStakedTimestamp[_collectionAddr][_tokenIDs[i]];
    //     }
    //     return (_tokenIDs, _timestamps);
    // }

    function getTotalStakedItemsCount(uint256 _collectionID) external view returns (uint256) {
        CollectionInfo storage collection = collectionInfo[_collectionID];
        return collection.totalAmountStaked;
    }

    function onERC721Received(
        address,
        address,
        uint256
    ) public pure returns (bytes4) {
        return _ERC721_RECEIVED;
    }

    function _removeElement(uint256[] storage _array, uint256 _element) internal {

        for (uint256 i; i < _array.length; i++) {
            if (_array[i] == _element) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }
        }
    }

}
