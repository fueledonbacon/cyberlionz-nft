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

    struct UserInfo {
        mapping(address => uint256[]) stakedTokens;
        mapping(address => uint256[]) timeStaked;
        uint256 amountStaked;
    }

    struct CollectionInfo {
        address collectionAddress;
        uint256 rewardPerDay;
        uint256 totalAmountStaked;
    }

    mapping(address => UserInfo) public userInfo;
    mapping(address => mapping(uint256 => address)) public tokenOwners;

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
        UserInfo storage user = userInfo[_userAddress];
        CollectionInfo storage collection = collectionInfo[_collectionID];
        
        IERC721(collection.collectionAddress).transferFrom(_userAddress, address(this), _tokenID);

        user.amountStaked += 1;
        collection.totalAmountStaked += 1;
        user.timeStaked[collection.collectionAddress][_tokenID] = block.timestamp;
        user.stakedTokens[collection.collectionAddress].push(_tokenID);
        tokenOwners[collection.collectionAddress][_tokenID] = _userAddress;
    }

    function batchStake(uint256 _cid, uint256[] memory _ids) external {
        for (uint256 i = 0; i < _ids.length; ++i) {
            _stake(msg.sender, _cid, _ids[i]);
        }
    }

    function batchUnstake(uint256 _cid, uint256[] memory _ids) external {
        for (uint256 i = 0; i < _ids.length; ++i) {
            _unstake(msg.sender, _cid, _ids[i]);
        }
    }

    function unstake(uint256 _collectionID, uint256 _tokenID) external {
        _unstake(msg.sender, _collectionID, _tokenID);
    }

    function mintertest(uint256 payableAmount) public {
        Mintable(rewardsTokenAddress).mint(msg.sender,payableAmount);
    }

    function _unstake(
        address _userAddress,
        uint256 _collectionID,
        uint256 _tokenID
    ) internal {
        UserInfo storage user = userInfo[_userAddress];
        CollectionInfo storage collection = collectionInfo[_collectionID];

        require(
            tokenOwners[collection.collectionAddress][_tokenID] == _userAddress,
            "sender doesn't owns this token"
        );

        _claimReward(msg.sender, _collectionID, _tokenID);
        

        _removeElement(user.stakedTokens[collection.collectionAddress], _tokenID);

        delete tokenOwners[collection.collectionAddress][_tokenID];

        user.timeStaked[collection.collectionAddress][_tokenID] = block.timestamp;
        user.amountStaked -= 1;
        collection.totalAmountStaked -= 1;
        if (user.amountStaked == 0) {
            delete userInfo[_userAddress];
        }
        IERC721(collection.collectionAddress).transferFrom(address(this), _userAddress, _tokenID);
        
    }

    function claimableReward(address _userAddress, uint256 _collectionID,uint256 _tokenID) public view returns(uint256) {
        UserInfo storage user = userInfo[_userAddress];
        CollectionInfo storage collection = collectionInfo[_collectionID];
        uint256 payableAmount = (block.timestamp - user.timeStaked[collection.collectionAddress][_tokenID])
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

    function getUserInformation(address _userAddress, address _collectionAddr, uint256 _tokenID) external view returns (uint256[] memory, uint256, uint256) {
        return (userInfo[_userAddress].stakedTokens[_collectionAddr], userInfo[_userAddress].timeStaked[_collectionAddr][_tokenID], userInfo[_userAddress].amountStaked);
    }

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
