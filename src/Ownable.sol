pragma solidity ^0.4.24;

import "./Burnable.sol";

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is Burnable {

  address public owner;
  address public ownerCandidate;

  /**
   * @dev Fired whenever ownership is successfully transferred.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    ownerCandidate = _newOwner;
  }

  /**
   * @dev New ownerschip Confirmation.
   */
  function acceptOwnership() public {
    _acceptOwnership();
  }

  /**
   * @dev New ownerschip confirmation internal.
   */
  function _acceptOwnership() internal {
    require(msg.sender == ownerCandidate);
    emit OwnershipTransferred(owner, ownerCandidate);
    owner = ownerCandidate;
    ownerCandidate = address(0);
  }

  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   * In case stuff goes bad.
   */
  function destroy() public onlyOwner {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) public onlyOwner {
    selfdestruct(_recipient);
  }

}
