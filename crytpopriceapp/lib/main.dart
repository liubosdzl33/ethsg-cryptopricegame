import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web3dart/web3dart.dart';

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

  Future<void> submitGuess() async {
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
              onPressed: submitGuess,
              child: Text('Submit Guess'),
            ),
          ],
        ),
      ),
    );
  }
}