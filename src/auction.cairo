#[starknet::interface]
trait IAuction<T>{
    fn register_item(ref self:T,item_name: ByteArray);

    fn unregister_item(ref self:T,item_name: ByteArray);

    fn bid(ref self:T,item_name:ByteArray,amount:u32);

    fn get_highest_bidder(self:@T, item_name:ByteArray)->u32;
    
    fn is_registered(self:@T, item_name:ByteArray)->bool;

}

#[starknet::contract]
mod Auction{

    #[storage]
    struct Storage{
         bid : Map<ByteArray,u32>,
         register:  Map<ByteArray,bool>
    }
    //TODO Implement interface and events .. deploy contract
}