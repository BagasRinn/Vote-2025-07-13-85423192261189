import Nat "mo:base/Nat";
import Text "mo:base/Text";
import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Iter "mo:base/Iter";

actor Vote {
  // Daftar opsi voting
  private let options = ["Kucing", "Anjing", "Burung"];
  
  // Penyimpanan hasil voting dengan stable storage
  private stable var votesEntries : [(Text, Nat)] = [];
  private var votes = HashMap.HashMap<Text, Nat>(3, Text.equal, Text.hash);

  // System functions untuk upgrade stability
  system func preupgrade() {
    votesEntries := Iter.toArray(votes.entries());
  };

  system func postupgrade() {
    votesEntries := [];
  };

  // Inisialisasi hasil voting ke 0
  private func initializeVotes() {
    for (opt in options.vals()) {
      if (votes.get(opt) == null) {
        votes.put(opt, 0);
      };
    };
  };

  // Panggil inisialisasi
  initializeVotes();

  // Restore from stable storage
  for ((key, value) in votesEntries.vals()) {
    votes.put(key, value);
  };

  // Fungsi untuk mendapatkan opsi voting yang tersedia
  public query func getOptions(): async [Text] {
    options
  };

  // Fungsi untuk melakukan voting
  public func vote(option: Text): async {#ok: Text; #err: Text} {
    // Validasi input
    if (option == "") {
      return #err("Opsi tidak boleh kosong.");
    };
    
    // Cek apakah opsi valid
    let isValidOption = Array.find<Text>(options, func(x) { x == option });
    switch (isValidOption) {
      case (?_) {
        // Opsi valid, lakukan voting
        switch (votes.get(option)) {
          case (?currentVotes) { 
            votes.put(option, currentVotes + 1);
          };
          case null { 
            votes.put(option, 1);
          };
        };
        #ok("Vote berhasil untuk " # option # "!")
      };
      case null {
        #err("Opsi '" # option # "' tidak ditemukan. Opsi yang tersedia: " # 
             Array.foldLeft<Text, Text>(options, "", func(acc, x) { 
               if (acc == "") x else acc # ", " # x 
             }))
      };
    };
  };

  // Fungsi untuk melihat hasil voting
  public query func getResults(): async [(Text, Nat)] {
    Iter.toArray(votes.entries())
  };

  // Fungsi untuk mendapatkan total votes
  public query func getTotalVotes(): async Nat {
    var total = 0;
    for ((_, count) in votes.entries()) {
      total += count;
    };
    total
  };

  // Fungsi untuk mendapatkan pemenang
  public query func getWinner(): async ?Text {
    var winner: ?Text = null;
    var maxVotes = 0;
    
    for ((option, count) in votes.entries()) {
      if (count > maxVotes) {
        maxVotes := count;
        winner := ?option;
      };
    };
    
    if (maxVotes > 0) winner else null
  };

  // Fungsi untuk reset voting (hanya untuk testing)
  public func resetVotes(): async Text {
    for (opt in options.vals()) {
      votes.put(opt, 0);
    };
    "Voting telah direset."
  };
}