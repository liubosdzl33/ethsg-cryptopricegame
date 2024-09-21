import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web3dart/web3dart.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(CryptoPriceGame());
}

class CryptoPriceGame extends StatelessWidget {
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
  double userPrice = 0.0;
  bool isVerified = false;
  final TextEditingController _guessController = TextEditingController();
  late WebViewController _webViewController;

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
          ],
        ),
      ),
    );
  }
}