/**
 *Submitted for verification at Arbiscan on 2023-05-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ERC1155_Interface {
  function balanceOf( address account, uint256 id ) external view returns( uint256 );
  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
  function gift_mint( uint256 amount, string memory uri, address owner ) external;
}

interface ERC721_Interface {
  function ownerOf(uint256 tokenId) view external returns (address);
  function safeTransferFrom(address from,address to,uint256 tokenId) external;
  function gift_mint(string memory tokenUri, address owner) external returns(uint256);
}

interface ERC20_Interface {
  function transferFrom( address from, address to, uint256 amount ) external returns ( bool );	
}

interface Common_Interface {
  function isApprovedForAll(address account, address operator) view external returns( bool );
}



// This `Split_payment` struct
// hold a single address and how much percentage to send
// in this address. Say we have set 3 account for split payment
// this struct will hold 1 account address and how much % to send
// to this address.
struct Split_Payment {
	address addr;
	uint per;
}

struct Token_Details {
  address owner;
  uint chain_id;
  uint price;
  uint standard; // 721,1155
  uint total_split_payment_accounts;
  uint amount;
  bool is_listed;
  bool is_exist;
  bool has_split_payment;
  mapping( uint => Split_Payment ) index_to_split_payment;
}

struct STORAGE {
	mapping( address => mapping( address => mapping( uint256 => Token_Details ) ) ) con_user_id_details;
	mapping( address => mapping( uint256 => uint256 ) ) con_id_royalty;
	mapping( address => mapping( uint256 => address ) ) con_id_creator;
	mapping( address => mapping( address => mapping( uint256 => bool ) ) ) con_user_id_secondSale;
}


contract ImplementationV2 {
  STORAGE S; 

  function list_for_sale (
	address[] memory _params0, // 0.contract_address, 1.creator_address, 2.split_payment_addresses_from_index_2
	uint256[] memory _params1, // 0.token_id, 1.chain_id, 2.price, 3.royalty_percentage, 4.standard, 5.amount, 6.split_payment_percentages_from_index_6
	bool[] memory _params2 	   // 0.has_split_payment, 1.has_royalty
  ) public payable 
	only_owner( _params0[0], msg.sender, _params1[0], _params1[4], _params1[5] )
	market_need_access( _params0[0], msg.sender )
  {
	//STORE DATA
	S.con_user_id_details[ _params0[0] ][ msg.sender ][ _params1[0] ].owner = msg.sender;
	S.con_user_id_details[ _params0[0] ][ msg.sender ][ _params1[0] ].chain_id = _params1[1];
	S.con_user_id_details[ _params0[0] ][ msg.sender ][ _params1[0] ].price = _params1[2];
	S.con_user_id_details[ _params0[0] ][ msg.sender ][ _params1[0] ].standard = _params1[4];
	S.con_user_id_details[ _params0[0] ][ msg.sender ][ _params1[0] ].is_listed = true;
	S.con_user_id_details[ _params0[0] ][ msg.sender ][ _params1[0] ].is_exist = true;
	S.con_user_id_details[ _params0[0] ][ msg.sender ][ _params1[0] ].has_split_payment = _params2[0];
	S.con_user_id_details[ _params0[0] ][ msg.sender ][ _params1[0] ].amount = _params1[5];


	//ADD ROYALITY AND CREATOR IF NOT SET ALREADY
	if( S.con_id_royalty[ _params0[0] ][ _params1[0] ] == 0 ) {
		 S.con_id_royalty[ _params0[0] ][ _params1[0] ] = _params1[3];
	}
	if( S.con_id_creator[ _params0[0] ][ _params1[0] ] == address(0) ) {
		 S.con_id_creator[ _params0[0] ][ _params1[0] ] = _params0[1];
	}


	//SET SPLIT PAYMENT IF HAS
	if( _params2[0] == true ) {
		uint256 i;
		//set addresses
		for( i = 0;  i < _params0.length; i++ ) {
			if( i >= 2 ) {
				S.con_user_id_details[ _params0[0] ][ msg.sender ][ _params1[0] ].index_to_split_payment[ i - 1 ].addr = _params0[i];
				S.con_user_id_details[ _params0[0] ][ msg.sender ][ _params1[0] ].total_split_payment_accounts += 1; 
			}
		}

		//set percentage
		for( i = 0;  i < _params1.length; i++ ) {
			if( i >= 6 ) {
				S.con_user_id_details[ _params0[0] ][ msg.sender ][ _params1[0] ].index_to_split_payment[ i - 5 ].per = _params1[i];
			}
		}

	}

  }


  function unlist_for_sale( address con, uint256 token_id ) public {
	require(
		S.con_user_id_details[con][ msg.sender ][token_id].owner == msg.sender,
		"O O" //only owner
	);

	S.con_user_id_details[con][ msg.sender ][token_id].is_listed = false;
  }



  function buy (
	address[3] memory _params0, // contract_address, owner_address, erc20Contractaddress 
	uint256[4] memory _params1, // token_id, standard, amount, listingFee
	bool[1] memory _params2     // is_erc_20
  ) public payable
  {
	      require(
	      	S.con_user_id_details[ _params0[0] ][ _params0[1] ][ _params1[0] ].owner != msg.sender,
	      	"A O" //already owner
	      );

	      require(
	      	S.con_user_id_details[ _params0[0] ][ _params0[1] ][ _params1[0] ].is_listed == true,
	      	"N L" //not listed
	      );

		  uint256 _price = S.con_user_id_details[ _params0[0] ][ _params0[1] ][ _params1[0] ].price * _params1[2] ;
		  if( _params2[0]  != true ) {
		  		require( msg.value == _price , "P N C" ); //price not correct
				_price = msg.value - _params1[3]; // [3] listingFee
		  }

		  uint256 _royality;
		  uint256 standard = S.con_user_id_details[ _params0[0] ][ _params0[1] ][ _params1[0] ].standard; 
		  address _token_creator =  S.con_id_creator[ _params0[0] ][ _params1[0] ];

		  //CHECK IF TOKEN HAS ANY ROYALTY AND ITS SECONDARY SALE.
		  if( S.con_id_royalty[ _params0[0] ][ _params1[0] ] != 0 && S.con_user_id_secondSale[ _params0[0] ][ _params0[1] ][ _params1[0] ] ) {

				 //ROYALTY PAYMENT ( TOTAL ROYALTY )
				 _royality = calc_percentage( _price, S.con_id_royalty[ _params0[0] ][ _params1[0] ]  );

				  //IF SPLIT PAYMENT IS SET THEN SEND THE ROYALTY IN DIFFERENT ACCOUNT	
				  if( S.con_user_id_details[ _params0[0] ][ _token_creator ][ _params1[0] ].has_split_payment == true ) {
						  if( _params2[0] ) {
								process_split_payment( _params0[0], _token_creator, _params1[0], S.con_user_id_details[ _params0[0] ][ _token_creator ][ _params1[0] ].total_split_payment_accounts, _royality, _params0[2] );		
						  }else{
								process_split_payment( _params0[0], _token_creator, _params1[0], S.con_user_id_details[ _params0[0] ][ _token_creator ][ _params1[0] ].total_split_payment_accounts, _royality, address(0) );		
						  }

				  } else {
				  //SPLIT PAYMENT NOT SET SEND ROYALTY IN SINGLE ACCOUNT
						  if( _params2[0] ) {
				  			send_money( _params0[2], _token_creator, _royality, 20);
						  }else{
				  			send_money( _params0[0], _token_creator, _royality, standard );
						  }
				  }

				  //PRICE MONEY PAYMENT ( SUBTRACT ROYALTY FROM PRICE )

				  //IF SPLIT PAYMENT IS SET THEN SEND THE PRICE MONEY IN DIFFERENT ACCOUNT	
				  if( S.con_user_id_details[ _params0[0] ][ _params0[1] ][ _params1[0] ].has_split_payment == true ) {
						  if( _params2[0] ) {
								process_split_payment( _params0[0], _params0[1], _params1[0], S.con_user_id_details[ _params0[0] ][ _params0[1] ][ _params1[0] ].total_split_payment_accounts, ( _price - _royality ), _params0[2] );		
						  }else {
								process_split_payment( _params0[0], _params0[1], _params1[0], S.con_user_id_details[ _params0[0] ][ _params0[1] ][ _params1[0] ].total_split_payment_accounts, ( _price - _royality ), address(0) );		
						  }

				  } else {
				  //SPLIT PAYMENT NOT SET SEND PRICE MONEY  IN SINGLE ACCOUNT
						if( _params2[0] ) {
				  			send_money( _params0[2], _params0[1], ( _price - _royality ), 20);
						}else {
				  			send_money( _params0[0], _params0[1], ( _price - _royality ), standard );
						}
				  }


		  } else{
		  //DONT HAVE ANY ROYALTY, NO NEED TO SUBTRACT ROYALTY FROM PRICE

				  //IF SPLIT PAYMENT IS SET THEN SEND THE PRICE MONEY IN DIFFERENT ACCOUNT	
				  if( S.con_user_id_details[ _params0[0] ][ _params0[1] ][ _params1[0] ].has_split_payment == true ) {
						  if( _params2[0] ) {
								process_split_payment( _params0[0], _params0[1], _params1[0], S.con_user_id_details[ _params0[0] ][ _params0[1] ][ _params1[0] ].total_split_payment_accounts, _price, _params0[2] );		
						  }else{
								process_split_payment( _params0[0], _params0[1], _params1[0], S.con_user_id_details[ _params0[0] ][ _params0[1] ][ _params1[0] ].total_split_payment_accounts, _price, address(0) );		
						  }

				  } else {
				  //SPLIT PAYMENT NOT SET SEND PRICE MONEY  IN SINGLE ACCOUNT
						if( _params2[0] ) {
				  			send_money( _params0[2], _params0[1], _price , 20 );
						}else{
				  			send_money( _params0[0], _params0[1], _price , standard );
						}
				  }

		  }

		  // BUY COMPLEATE TRANSFER THE TOKEN
		  if( standard == 721 ) {
				ERC721_Interface( _params0[0] ).safeTransferFrom( S.con_user_id_details[ _params0[0] ][ _params0[1] ][ _params1[0] ].owner, msg.sender, _params1[0] );

		  		// BUY COMPLEATE UPDATE SOME DATA
				S.con_user_id_details[ _params0[0] ][ S.con_user_id_details[ _params0[0] ][ _params0[1] ][ _params1[0] ].owner ][ _params1[0] ].is_listed = false;
		  }

		  if( standard == 1155 ) {
    		   ERC1155_Interface( _params0[0] ).safeTransferFrom( S.con_user_id_details[ _params0[0] ][ _params0[1] ][ _params1[0] ].owner, msg.sender, _params1[0], _params1[2], "0x0" );
		  	   // BUY COMPLEATE UPDATE SOME DATA
			   uint256 _left = S.con_user_id_details[ _params0[0] ][ _params0[1] ][ _params1[0] ].amount - _params1[2];
			   S.con_user_id_details[ _params0[0] ][ _params0[1] ][ _params1[0] ].amount = _left;
			   S.con_user_id_details[ _params0[0] ][ _params0[1] ][ _params1[0] ].is_listed = _left > 0 ;
		  }

		  S.con_user_id_secondSale[ _params0[0] ][ msg.sender ][ _params1[0] ] = true;

  }

  function lazy_mint (
	address[] memory _params_one, //contract_address, token_creator, erc20Con, _split_payment_accounts_from_index_3
	uint256[] memory _params_two, //chain_id, price_of_one_copy, royalty_percentage, token_id, amount, standard, buy_amount, listingFee,  _split_payment_percentages_from_index_8
	bool[4] memory _params_three, //is_erc_1155, has_split_payment, has_royalty, is_erc_20
	string memory tokenUri
  ) public payable 
  {
	//error check 
	if( _params_three[3] != true ) {
		  require( ( _params_two[1] * _params_two[6] )  == msg.value, "S C P" ); //send correct price
	}

	/*address erc20Con = address(0);*/
	/*if( _params_three[3] ){ erc20Con = _params_one[2]; }*/

	//ADD ROYALITY AND CREATOR IF NOT SET ALREADY
	if( S.con_id_royalty[ _params_one[0] ][ _params_two[3] ] == 0 ) {
		 S.con_id_royalty[ _params_one[0] ][ _params_two[3] ] = _params_two[2];
	}
	if( S.con_id_creator[ _params_one[0] ][ _params_two[3] ] == address(0) ) {
		 S.con_id_creator[ _params_one[0] ][ _params_two[3] ] = _params_one[1];
	}

	//STORE DATA FOR CREATOR
	S.con_user_id_details[ _params_one[0] ][ _params_one[1] ][ _params_two[3] ].owner = _params_one[1];
	S.con_user_id_details[ _params_one[0] ][ _params_one[1] ][ _params_two[3] ].chain_id = _params_two[0];
	S.con_user_id_details[ _params_one[0] ][ _params_one[1] ][ _params_two[3] ].price = _params_two[1];
	S.con_user_id_details[ _params_one[0] ][ _params_one[1] ][ _params_two[3] ].standard = _params_two[5];
	S.con_user_id_details[ _params_one[0] ][ _params_one[1] ][ _params_two[3] ].is_listed = true;
	S.con_user_id_details[ _params_one[0] ][ _params_one[1] ][ _params_two[3] ].is_exist = true;
	S.con_user_id_details[ _params_one[0] ][ _params_one[1] ][ _params_two[3] ].amount = _params_two[4] - _params_two[6];
	S.con_user_id_details[ _params_one[0] ][ _params_one[1] ][ _params_two[3] ].has_split_payment = _params_three[1];

	//SET SPLIT PAYMENT IF HAS
	if( _params_three[1] == true ) {
		uint256 i;
		//set addresses
		for( i = 0;  i < _params_one.length; i++ ) {
			if( i >= 3 ) {
				S.con_user_id_details[ _params_one[0] ][ _params_one[1] ][ _params_two[3] ].index_to_split_payment[ i - 2 ].addr = _params_one[i];
				S.con_user_id_details[ _params_one[0] ][ _params_one[1] ][ _params_two[3] ].total_split_payment_accounts += 1; 
			}
		}

		//set percentage
		for( i = 0;  i < _params_two.length; i++ ) {
			if( i >= 8 ) {
				S.con_user_id_details[ _params_one[0] ][ _params_one[1] ][ _params_two[3] ].index_to_split_payment[ i - 7 ].per = _params_two[i];
			}
		}

	}

	//1155 standard
	if(_params_three[0]){
		//mint the token	
		ERC1155_Interface(_params_one[0]).gift_mint( _params_two[4], tokenUri, _params_one[1] );
	
	//721 standard
	}else{
		//mint the token
		ERC721_Interface( _params_one[0] ).gift_mint( tokenUri, _params_one[1] );
	}

	buy( 
		[ _params_one[0], _params_one[1], _params_one[2] ],
		[ _params_two[3], _params_two[5], _params_two[6], _params_two[7] ],
		[ _params_three[3] ]
	);

  }


  //HELPER FUNCTION
  function process_split_payment ( address con, address user, uint256 token_id, uint256 total_accounts, uint256 money, address erc20Con ) private {

		
		// LOOP THROW ALL ADDRESS AND ROYALTY
		for( uint256 i = 1;  i <= total_accounts; i++  ) {

		  	// CHECK ADDRESS AND PERCENTAGE ARE NOT BLANK	
		  	if(
		  		S.con_user_id_details[ con ][ user ][ token_id ].index_to_split_payment[ i ].addr != address(0) &&
		  		S.con_user_id_details[ con ][ user ][ token_id ].index_to_split_payment[ i ].per != 0 
		  	  )
			  {

		  		    //SEND ROYALTY
					uint256 payment = calc_percentage( money, S.con_user_id_details[ con ][ user ][ token_id ].index_to_split_payment[ i ].per );
					if( erc20Con == address(0) ) {
							send_money(
								erc20Con,
								S.con_user_id_details[ con ][ user ][ token_id ].index_to_split_payment[ i ].addr,
								payment,
								S.con_user_id_details[ con ][ user ][ token_id ].standard 
							);
					}else{
							send_money(
								erc20Con,
								S.con_user_id_details[ con ][ user ][ token_id ].index_to_split_payment[ i ].addr,
								payment,
								20
							);

					}
				 
		     }

		}

  }

  function send_money ( address con, address receiver, uint256 amount, uint256 standard ) private {

		//CHECK CONTRACT STANDARD AND SEND MONEY THAT WAY	
		if( standard == 721 ) {
		   //SEND MONEY
		   payable( receiver ).transfer( amount );

		}

		if( standard == 1155 ) {
		   //SEND MONEY
		   payable( receiver ).transfer( amount );
		}

		if( standard == 20 ) {
		   bool success = ERC20_Interface( con ).transferFrom( msg.sender, receiver, amount );
		   require( success, "ERC20 T T F." ); // erc20 token transfer fail
		}

	  require( standard == 721 || standard == 1155 || standard == 20, "I S" ); //invalid standard

  }


  function calc_percentage( uint256 _amount, uint256 _percentage ) private pure returns ( uint256 ) {
  	//_percentage is send by multiplying with 100
  	//to get the percentage we devide the percentage with 10000
  	return _amount * _percentage / 10000;
  }

  //MODIFIER
   modifier only_owner ( address _contract_add, address _user_add, uint256 _token_id, uint256 _standard, uint256 amount ) {
	  if( _standard == 721 ) {
			require(
			  ERC721_Interface( _contract_add ).ownerOf( _token_id ) == msg.sender,
			  "O O" //only owner
			);
	  }

	  if( _standard == 1155 ) {
		   require(
			  ERC1155_Interface( _contract_add ).balanceOf( _user_add, _token_id ) >= amount,
			  "O O" //only owner
		   );
	  }

	  require( _standard == 721 || _standard == 1155, "I S" ); // invalid standard

	  _;
  }

  modifier market_need_access ( address _contract_add, address _user_add ) {
	  require(
	  	  Common_Interface( _contract_add ).isApprovedForAll( _user_add, address(this) ),
		  "M N A" // market need access
	  );

	  _;
  }

}