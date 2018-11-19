pragma solidity ^0.4.24;
import "./Pausable.sol";
contract Rento is Pausable {
  using SafeMath for uint256;
  string public name = "Rento";
  string public symbol = "RTO";
  uint8 public decimals = 8;
  /**
   * @dev representing 1.0.
   */
  uint256 public constant UNIT      = 100000000;
  uint256 constant INITIAL_SUPPLY   = 600000000 * UNIT;
  uint256 constant SALE_SUPPLY      = 264000000 * UNIT;
  uint256 internal SALE_SENT        = 0;
  uint256 constant OWNER_SUPPLY     = 305000000 * UNIT;
  uint256 internal OWNER_SENT       = 0;
  uint256 constant BOUNTY_SUPPLY    = 6000000 * UNIT;
  uint256 internal BOUNTY_SENT      = 0;
  uint256 constant ADVISORS_SUPPLY  = 25000000 * UNIT;
  uint256 internal ADVISORS_SENT    = 0;
  struct Stage {
     uint8 cents;
     uint256 limit;
  } 
  Stage[] stages;
  /**
   * @dev Stages prices in cents
   */
  mapping(uint => uint256) rates;
  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    stages.push(Stage( 2, 0));
    stages.push(Stage( 6, 26400000 * UNIT));
    stages.push(Stage( 6, 52800000 * UNIT));
    stages.push(Stage(12, 158400000 * UNIT));
    stages.push(Stage(12, SALE_SUPPLY));
  }
  /**
   * @dev Sell tokens to address based on USD cents value.
   * @param _to Buyer address.
   * @param _value USC cents value.
   */
  function sellWithCents(address _to, uint256 _value) public
    onlyAdmin whenNotPaused
    returns (bool success) {
      return _sellWithCents(_to, _value);
  }
  /**
   * @dev Sell tokens to address array based on USD cents array values.
   */
  function sellWithCentsArray(address[] _dests, uint256[] _values) public
    onlyAdmin whenNotPaused
    returns (bool success) {
      require(_dests.length == _values.length);
      for (uint32 i = 0; i < _dests.length; i++)
        if(!_sellWithCents(_dests[i], _values[i])) {
          revert();
          return false;
        }
      return true;
  }
  /**
   * @dev Sell tokens to address based on USD cents value.
   * @param _to Buyer address.
   * @param _value USC cents value.
   */
  function _sellWithCents(address _to, uint256 _value) internal
    onlyAdmin whenNotPaused
    returns (bool) {
      require(_to != address(0) && _value > 0);
      uint256 tokens_left = 0;
      uint256 tokens_right = 0;
      uint256 price_left = 0;
      uint256 price_right = 0;
      uint256 tokens;
      uint256 i_r = 0;
      uint256 i = 0;
      while (i < stages.length) {
        if(SALE_SENT >= stages[i].limit) {
          if(i == stages.length-1) {
            i_r = i;
          } else {
            i_r = i + 1;
          }
          price_left = uint(stages[i].cents);
          price_right = uint(stages[i_r].cents);
        }
        i += 1;
      }
      if(price_left <= 0) {
        revert();
        return false;
      }
      tokens_left = _value.mul(UNIT).div(price_left);
      if(SALE_SENT.add(tokens_left) <= stages[i_r].limit) {
        tokens = tokens_left;
      } else {
        tokens_left = stages[i_r].limit.sub(SALE_SENT);
        tokens_right = UNIT.mul(_value.sub((tokens_left.mul(price_left)).div(UNIT))).div(price_right);
      }
      tokens = tokens_left.add(tokens_right);
      if(SALE_SENT.add(tokens) > SALE_SUPPLY) {
        revert();
        return false;
      }
      balances[_to] = balances[_to].add(tokens);
      SALE_SENT = SALE_SENT.add(tokens);
      emit Transfer(this, _to, tokens);
      return true;
  }
  /**
   * @dev Transfer tokens from contract directy to address.
   * @param _to Buyer address.
   * @param _value Tokens value.
   */
  function sellDirect(address _to, uint256 _value) public
    onlyAdmin whenNotPaused
      returns (bool success) {
        require(_to != address(0) && _value > 0 && SALE_SENT.add(_value) <= SALE_SUPPLY);
        balances[_to] = balances[_to].add(_value);
        SALE_SENT = SALE_SENT.add(_value);
        emit Transfer(this, _to, _value);
        return true;
  }
  /**
   * @dev Sell tokens to address array based on USD cents array values.
   */
  function sellDirectArray(address[] _dests, uint256[] _values) public
    onlyAdmin whenNotPaused returns (bool success) {
      require(_dests.length == _values.length);
      for (uint32 i = 0; i < _dests.length; i++) {
         if(_values[i] <= 0 || !sellDirect(_dests[i], _values[i])) {
            revert();
            return false;
         }
      }
      return true;
  }
  /**
   * @dev Transfer tokens from contract directy to owner.
   * @param _value Tokens value.
   */
  function transferOwnerTokens(uint256 _value) public
    onlyAdmin whenNotPaused returns (bool success) {
      require(_value > 0 && OWNER_SENT.add(_value) <= OWNER_SUPPLY);
      balances[owner] = balances[owner].add(_value);
      OWNER_SENT = OWNER_SENT.add(_value);
      emit Transfer(this, owner, _value);
      return true;
  }
  /**
   * @dev Transfer Bounty Tokens from contract.
   * @param _to Bounty recipient address.
   * @param _value Tokens value.
   */
  function transferBountyTokens(address _to, uint256 _value) public
    onlyAdmin whenNotPaused returns (bool success) {
      require(_to != address(0) && _value > 0 && BOUNTY_SENT.add(_value) <= BOUNTY_SUPPLY);
      balances[_to] = balances[_to].add(_value);
      BOUNTY_SENT = BOUNTY_SENT.add(_value);
      emit Transfer(this, _to, _value);
      return true;
  }
  /**
   * @dev Transfer Bounty Tokens from contract to multiple recipients ant once.
   * @param _to Bounty recipient addresses.
   * @param _values Tokens values.
   */
  function transferBountyTokensArray(address[] _to, uint256[] _values) public
    onlyAdmin whenNotPaused returns (bool success) {
      require(_to.length == _values.length);
      for (uint32 i = 0; i < _to.length; i++)
        if(!transferBountyTokens(_to[i], _values[i])) {
          revert();
          return false;
        }
      return true;
  }
    
  /**
   * @dev Transfer Advisors Tokens from contract.
   * @param _to Advisors recipient address.
   * @param _value Tokens value.
   */
  function transferAdvisorsTokens(address _to, uint256 _value) public
    onlyAdmin whenNotPaused returns (bool success) {
      require(_to != address(0) && _value > 0 && ADVISORS_SENT.add(_value) <= ADVISORS_SUPPLY);
      balances[_to] = balances[_to].add(_value);
      ADVISORS_SENT = ADVISORS_SENT.add(_value);
      emit Transfer(this, _to, _value);
      return true;
  }
    
  /**
   * @dev Transfer Advisors Tokens from contract for multiple advisors.
   * @param _to Advisors recipient addresses.
   * @param _values Tokens valuees.
   */
  function transferAdvisorsTokensArray(address[] _to, uint256[] _values) public
    onlyAdmin whenNotPaused returns (bool success) {
      require(_to.length == _values.length);
      for (uint32 i = 0; i < _to.length; i++)
        if(!transferAdvisorsTokens(_to[i], _values[i])) {
          revert();
          return false;
        }
      return true;
  }
  /**
   * @dev Current Sale states methods.
   */
  function soldTokensSent() external view returns (uint256) {
    return SALE_SENT;
  }
  function soldTokensAvailable() external view returns (uint256) {
    return SALE_SUPPLY.sub(SALE_SENT);
  }
  function ownerTokensSent() external view returns (uint256) {
    return OWNER_SENT;
  }
  function ownerTokensAvailable() external view returns (uint256) {
    return OWNER_SUPPLY.sub(OWNER_SENT);
  }
  function bountyTokensSent() external view returns (uint256) {
    return BOUNTY_SENT;
  }
  function bountyTokensAvailable() external view returns (uint256) {
    return BOUNTY_SUPPLY.sub(BOUNTY_SENT);
  }
  function advisorsTokensSent() external view returns (uint256) {
    return ADVISORS_SENT;
  }
  function advisorsTokensAvailable() external view returns (uint256) {
    return ADVISORS_SUPPLY.sub(ADVISORS_SENT);
  }
  /**
   * @dev Transfer tokens from msg.sender account directy to address array with values array.
   * param _dests  recipients.
   * @param _values Tokens values.
   */
  function transferArray(address[] _dests, uint256[] _values) public returns (bool success) {
      require(_dests.length == _values.length);
      for (uint32 i = 0; i < _dests.length; i++) {
        if(_values[i] > balances[msg.sender] || msg.sender == _dests[i] || _dests[i] == address(0)) {
          revert();
          return false;
        }
        balances[msg.sender] = balances[msg.sender].sub(_values[i]);
        balances[_dests[i]] = balances[_dests[i]].add(_values[i]);
        emit Transfer(msg.sender, _dests[i], _values[i]);
      }
      return true;
  }
}

