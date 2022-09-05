# @version ^0.2.16                                                                                                            
# @note whitehat probe                                                      
                                                                       
admin: address                                                           
MAX: constant(uint256) = 1024                                          
                                                                       
@external                                                              
def __init__():                                                        
  self.admin = msg.sender                                                
                                                                       
@external                                                              
@payable                                                               
def relay(_dest: address, _data: Bytes[MAX]) -> Bytes[128]:         
  assert msg.sender == self.admin                                                                                       
  response: Bytes[128] = b''                                           
  response = raw_call(                                        
    _dest,                                                             
    _data,                                                             
    value=msg.value,                                                   
    max_outsize=128,                                                                                          
  )                                                                    
  return response