import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web3dart/web3dart.dart';
import 'package:url_launcher/url_launcher.dart';

// Simulated Worldcoin SDK
class WorldcoinSDK {
  static Future<bool> verifyIdentity(String appId) async {
    // Simulate opening Worldcoin app or web page for verification
    const url = 'https://worldcoin.org/verify';
    if (await canLaunch(url)) {
      await launch(url);
      // In a real implementation, we'd wait for a callback or check a status
      await Future.delayed(Duration(seconds: 5)); // Simulating wait time
      return true; // Simulating successful verification
    }
    return false;
  }
}

void main() {
  runApp(CryptoGuessGame());
}

class CryptoGuessGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Guess Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedCoin = 'BTC';
  double currentPrice = 0.0;
  double userGuess = 0.0;
  bool isVerified = false;
  final TextEditingController _guessController = TextEditingController();

  // TODO: Replace with actual Ethereum node URL and contract address
  final String rpcUrl = 'https://mainnet.infura.io/v3/YOUR-PROJECT-ID';
  final String contractAddress = '0xYourContractAddress';

  @override
  void initState() {
    super.initState();
    fetchCurrentPrice();
  }

  Future<void> fetchCurrentPrice() async {
    final response = await http.get(Uri.parse(
        'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        currentPrice = data['bitcoin']['usd'].toDouble();
      });
    }
  }

  Future<void> verifyWithWorldcoin() async {
    bool verified = await WorldcoinSDK.verifyIdentity('YOUR_WORLDCOIN_APP_ID');
    setState(() {
      isVerified = verified;
    });
    if (verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Worldcoin verification successful!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Worldcoin verification failed. Please try again.')),
      );
    }
  }

  Future<void> submitGuess() async {
    if (!isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please verify with Worldcoin before submitting a guess.')),
      );
      return;
    }

    // TODO: Implement actual blockchain submission
    print('Submitting guess: $userGuess');
    
    // Example of how to interact with Ethereum contract (not fully implemented)
    final client = Web3Client(rpcUrl, http.Client());
    final credentials = EthPrivateKey.fromHex('YOUR_PRIVATE_KEY');
    final contract = DeployedContract(ContractAbi.fromJson('YOUR_ABI', 'GuessGame'), EthereumAddress.fromHex(contractAddress));
    final function = contract.function('submitGuess');
    
    await client.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: function,
        parameters: [BigInt.from(userGuess * 100)],  // Assuming the contract expects price in cents
      ),
      chainId: 1,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Guess submitted successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crypto Guess Game'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Current $selectedCoin Price: \$$currentPrice'),
            SizedBox(height: 20),
            TextField(
              controller: _guessController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter your price guess',
              ),
              onChanged: (value) {
                userGuess = double.tryParse(value) ?? 0.0;
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: verifyWithWorldcoin,
              child: Text('Verify with Worldcoin'),
              style: ElevatedButton.styleFrom(
                primary: isVerified ? Colors.green : Colors.blue,
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: isVerified ? submitGuess : null,
              child: Text('Submit Guess'),
            ),
          ],
        ),
      ),
    );
  }
}