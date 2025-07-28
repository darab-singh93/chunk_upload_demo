import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MaterialApp(home: UploadPage()));
}

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  File? selectedFile;
  bool isUploading = false;
  double progress = 0.0;
  final chunkSize = 1024 * 1024; // 1MB

  /// Command for M1 to get IP = ipconfig getifaddr en0

  final uploadUrl = "http://10.23.248.51:3000/upload"; // Change to your IP
  final statusUrl = "http://10.23.248.51:3000/status"; // For uploaded bytes

  @override
  void initState() {
    super.initState();
    _tryResumeUpload();
  }

  Future<void> _tryResumeUpload() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString("lastUploadFilePath");
    final fileName = prefs.getString("lastUploadFileName");

    if (path != null && fileName != null && File(path).existsSync()) {
      setState(() => selectedFile = File(path));
      bool resume = await _showResumeDialog();

      if (resume) {
        uploadFileInChunks(selectedFile!);
      }
    }
  }

  Future<bool> _showResumeDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Resume Upload?"),
        content: const Text("A previous upload was interrupted. Resume it?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("No")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Yes")),
        ],
      ),
    ) ??
        false;
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() => selectedFile = File(result.files.single.path!));
      uploadFileInChunks(selectedFile!);
    }
  }

  Future<int> getUploadedSize(String fileName) async {
    final response = await http.get(Uri.parse('$statusUrl?fileName=$fileName'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['uploaded'] ?? 0;
    }
    return 0;
  }

  Future<void> uploadFileInChunks(File file) async {
    final prefs = await SharedPreferences.getInstance();
    final fileName = file.uri.pathSegments.last;
    final fileLength = await file.length();
    int uploaded = await getUploadedSize(fileName);

    setState(() {
      isUploading = true;
      progress = uploaded / fileLength;
    });

    prefs.setString("lastUploadFilePath", file.path);
    prefs.setString("lastUploadFileName", fileName);

    final raf = file.openSync(mode: FileMode.read);

    while (uploaded < fileLength) {
      final remaining = fileLength - uploaded;
      final currentChunkSize = remaining >= chunkSize ? chunkSize : remaining;
      raf.setPositionSync(uploaded);
      final chunk = raf.readSync(currentChunkSize);

      final request = http.Request("POST", Uri.parse(uploadUrl));
      request.headers.addAll({
        "Content-Type": "application/octet-stream",
        "Content-Range": "bytes $uploaded-${uploaded + currentChunkSize - 1}/$fileLength",
        "file-name": fileName,
      });
      request.bodyBytes = chunk;

      final response = await request.send();

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Upload failed. Will resume on restart.")),
        );
        break;
      }

      uploaded += currentChunkSize;
      prefs.setInt(fileName, uploaded);

      setState(() {
        progress = uploaded / fileLength;
      });
    }

    raf.closeSync();

    if (uploaded == fileLength) {
      prefs.remove(fileName);
      prefs.remove("lastUploadFilePath");
      prefs.remove("lastUploadFileName");

      setState(() {
        isUploading = false;
        progress = 1.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Upload complete!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).toStringAsFixed(1);
    return Scaffold(
      appBar: AppBar(title: const Text("Chunked File Upload")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: isUploading ? null : pickFile,
              child: const Text("📁 Pick File to Upload"),
            ),
            const SizedBox(height: 20),
            if (selectedFile != null) Text("Selected: ${selectedFile!.path.split('/').last}"),
            if (isUploading || progress > 0)
              Column(
                children: [
                  const SizedBox(height: 20),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 8),
                  Text("Upload Progress: $percent%"),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
