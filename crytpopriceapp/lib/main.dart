import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web3dart/web3dart.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  late WebViewController _webViewController;

  // Ethereum node URL (replace with your own)
  final String rpcUrl = 'https://mainnet.infura.io/v3/YOUR-PROJECT-ID';
  
  // Chainlink BTC/USD Price Feed address on Ethereum mainnet
  final String chainlinkBTCUSDAddress = '0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c';

  // ABI for Chainlink Price Feed
  final String chainlinkABI = '[{"inputs":[],"name":"latestRoundData","outputs":[{"internalType":"uint80","name":"roundId","type":"uint80"},{"internalType":"int256","name":"answer","type":"int256"},{"internalType":"uint256","name":"startedAt","type":"uint256"},{"internalType":"uint256","name":"updatedAt","type":"uint256"},{"internalType":"uint80","name":"answeredInRound","type":"uint80"}],"stateMutability":"view","type":"function"}]';

  @override
  void initState() {
    super.initState();
    fetchCurrentPrice();
  }

  Future<void> fetchCurrentPrice() async {
    try {
      final client = Web3Client(rpcUrl, http.Client());
      final contract = DeployedContract(
        ContractAbi.fromJson(chainlinkABI, 'ChainlinkPriceFeed'),
        EthereumAddress.fromHex(chainlinkBTCUSDAddress),
      );
      final function = contract.function('latestRoundData');
      final result = await client.call(contract: contract, function: function, params: []);
      
      // Chainlink returns price with 8 decimals
      final price = (result[1] as BigInt) / BigInt.from(100000000);
      
      setState(() {
        currentPrice = price.toDouble();
      });
    } catch (e) {
      print('Error fetching price: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch current price')),
      );
    }
  }

  Future<void> verifyWithWorldID() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Container(
            width: 300,
            height: 400,
            child: WebView(
              initialUrl: 'about:blank',
              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (WebViewController controller) {
                _webViewController = controller;
                _loadWorldIDHtml();
              },
              javascriptChannels: {
                JavascriptChannel(
                  name: 'WorldIDFlutter',
                  onMessageReceived: (JavascriptMessage message) {
                    final data = json.decode(message.message);
                    if (data['type'] == 'verification_success') {
                      setState(() {
                        isVerified = true;
                      });
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('WorldID verification successful!')),
                      );
                    }
                  },
                ),
              },
            ),
          ),
        );
      },
    );
  }

  void _loadWorldIDHtml() {
    String html = '''
      <!DOCTYPE html>
      <html>
      <head>
        <script src="https://cdn.worldcoin.org/js/worldcoin.js"></script>
      </head>
      <body>
        <div id="world-id-container"></div>
        <script>
          worldcoin.init('world-id-container', {
            action_id: 'your_action_id',
            signal: 'your_signal',
            app_name: 'Your App Name',
            enable_telemetry: true,
            onSuccess: (result) => {
              WorldIDFlutter.postMessage(JSON.stringify({
                type: 'verification_success',
                result: result
              }));
            },
            onError: (error) => {
              console.error(error);
              WorldIDFlutter.postMessage(JSON.stringify({
                type: 'verification_error',
                error: error.toString()
              }));
            }
          });
        </script>
      </body>
      </html>
    ''';

    _webViewController.loadUrl(Uri.dataFromString(
      html,
      mimeType: 'text/html',
      encoding: Encoding.getByName('utf-8')
    ).toString());
  }

  Future<void> submitGuess() async {
    if (!isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please verify with WorldID before submitting a guess.')),
      );
      return;
    }

    // TODO: Implement actual guess submission to your smart contract
    print('Submitting guess: $userGuess');
    
    // This is where you would interact with your game's smart contract
    // to submit the user's guess. The implementation will depend on your
    // specific smart contract design.

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
            Text('Current $selectedCoin Price: \$${currentPrice.toStringAsFixed(2)}'),
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
              onPressed: verifyWithWorldID,
              child: Text('Verify with WorldID'),
              style: ElevatedButton.styleFrom(
                primary: isVerified ? Colors.green : Colors.blue,
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: isVerified ? submitGuess : null,
              child: Text('Submit Guess'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchCurrentPrice,
              child: Text('Refresh Price'),
            ),
          ],
        ),
      ),
    );
  }
}