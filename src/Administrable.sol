pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "./Ownable.sol";

/**
 * @title Ownable
 * @dev The authentication manager details user accounts that have access to certain priviledges.
 */
contract Administrable is Ownable {

  using SafeERC20 for ERC20Basic;
  
  /**
   * @dev Map addresses to admins.
   */
  mapping (address => bool) admins;

  /**
   * @dev All admins that have ever existed.
   */
  address[] adminAudit;

  /**
   * @dev Globally enable or disable admin access.
   */
  bool allowAdmins = true;

   /**
   * @dev Fired whenever an admin is added to the contract.
   */
  event AdminAdded(address addedBy, address admin);

  /**
   * @dev Fired whenever an admin is removed from the contracts.
   */
  event AdminRemoved(address removedBy, address admin);

  /**
   * @dev Throws if called by any account other than the active admin or owner.
   */
  modifier onlyAdmin {
    require(isCurrentAciveAdmin(msg.sender));
    _;
  }

  /**
   * @dev Turn on admin role
   */
  function enableAdmins() public onlyOwner {
    require(allowAdmins == false);
    allowAdmins = true;
  }

  /**
   * @dev Turn off admin role
   */
  function disableAdmins() public onlyOwner {
    require(allowAdmins);
    allowAdmins = false;
  }

  /**
   * @dev Gets whether or not the specified address is currently an admin.
   */
  function isCurrentAdmin(address _address) public view returns (bool) {
    if(_address == owner)
      return true;
    else
      return admins[_address];
  }

  /**
   * @dev Gets whether or not the specified address is currently an active admin.
   */
  function isCurrentAciveAdmin(address _address) public view returns (bool) {
    if(_address == owner)
      return true;
    else
      return allowAdmins && admins[_address];
  }

  /**
   * @dev Gets whether or not the specified address has ever been an admin.
   */
  function isCurrentOrPastAdmin(address _address) public view returns (bool) {
    for (uint256 i = 0; i < adminAudit.length; i++)
      if (adminAudit[i] == _address)
        return true;
    return false;
  }

  /**
   * @dev Adds a user to our list of admins.
   */
  function addAdmin(address _address) public onlyOwner {
    require(admins[_address] == false);
    admins[_address] = true;
    emit AdminAdded(msg.sender, _address);
    adminAudit.length++;
    adminAudit[adminAudit.length - 1] = _address;
  }

  /**
   * @dev Removes a user from our list of admins but keeps them in the history.
   */
  function removeAdmin(address _address) public onlyOwner {
    require(_address != msg.sender);
    require(admins[_address]);
    admins[_address] = false;
    emit AdminRemoved(msg.sender, _address);
  }

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param _token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic _token) external onlyAdmin {
    uint256 balance = _token.balanceOf(this);
    _token.safeTransfer(msg.sender, balance);
  }

}
