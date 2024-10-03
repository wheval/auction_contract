#[derive(Drop, Serde, starknet::Store)]
pub struct Bid {
    item_name: ByteArray,
    amount: u32,
}

#[starknet::interface]
trait IAuction<T>{
    fn register_item(ref self:T,item_name: ByteArray);

    fn unregister_item(ref self:T,item_name: ByteArray);

    fn bid(ref self:T,item_name:ByteArray,amount:u32);

    fn get_highest_bidder(self:@T, item_name:ByteArray)->u32;
    
    fn is_registered(self:@T, item_name:ByteArray)->bool;

    fn get_all_items(self: @T) -> Array<ByteArray>;

}

#[starknet::contract]
pub mod Auction{    
    use core::starknet::{ContractAddress, get_caller_address};
    use super::IAuction;
    use starknet::storage::{
        Map, StorageMapWriteAccess, StorageMapReadAccess, StoragePointerReadAccess, 
        StoragePointerWriteAccess, Vec, VecTrait, MutableVecTrait
    }

    #[storage]
    struct Storage{
        bid : Map<ByteArray,u32>,           // item_name >> amount
        register:  Map<ByteArray,bool>      // item_name >> isRegistered
        allBids: Vec<u32>,                  // list of registered bids 
        allItems: Vec<ByteArray>,           // list of items names
        owner: felt252,  
    }
    //TODO Implement interface and events .. deploy contract
    #[derive(Drop, starknet::Event)]
    enum Event {
        ItemRegistered: ItemRegistered ,
        ItemUnregistered: ItemUnregistered,
        BidPlaced: BidPlaced,
    }
    struct ItemRegistered {
        item_name: ByteArray,
        registered_by: ContractAddress,
    }
    struct ItemUnregistered {
        item_name: ByteArray,
        unregistered_by: ContractAddress,
    }
    struct BidPlaced {
        bidder: ContractAddress,
        item_name: ByteArray,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, allItems: Array<ByteArray>) {
        self.owner.write(owner);
        self.allItems.write(allItems);
    }         

    #[abi(embed_v0)]
    impl AuctionImpl of IAuction<ContractState>{
        fn register_item (ref self: ContractState, item_name: ByteArray) {
            let caller = get_caller_address();
            let owner = self.owner.read();
            assert!(caller == owner, 'Only owner can register item');
            assert!(item_name != " ", 'Enter a valid name');
            self.register.write(item_name, true);          // register the item to be true
            self.allItems.append().write(item_name);

            self.emit(ItemRegistered { item_name, registered_by: caller });
        }

        fn unregister_item (ref self: ConstractState, item_name: ByteArray) {
            let caller = get_caller_address();
            let owner = self.owner.read();
            assert!(caller == owner, 'Only owner can register item');
            self.register.write(item_name, false);   

            self.emit(ItemUnregistered { item_name, unregistered_by: caller });
        }

        fn bid(ref self: ContractState, item_name:ByteArray, amount:u32) {
            let caller = get_caller_address();
            let owner = self.owner.read();
            assert!(caller != owner, 'Owners cannot bid');
            assert!(amount > 0, 'Amount cannot be zero');
            self.allBids.append().write(item_name, amount);
            self.bid.write(item_name, amount);
        }

        fn get_highest_bidder(self:@T, item_name:ByteArray)->u32 {
            let mut highest_bid = 0;
            let bids = self.allBids.read();
            for i in 0..bids.len() {
                if bids[i] > highest_bid {
                    highest_bid = bids[i];
                }
            }
            highest_bid
        }

        fn is_registered(self:@T, item_name:ByteArray)->bool {
            self.register.read(item_name)
        }

        fn get_all_items(self: @T) -> Array<ByteArray> {
            let mut all_items = array![];
            for i in 0..self.allItems.len() {
                all_items.append(self.allItems.at(i).read())
            }
            all_items
        }
        
    }   
}