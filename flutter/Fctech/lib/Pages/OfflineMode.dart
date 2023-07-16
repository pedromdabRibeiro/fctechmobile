import 'package:flutter/material.dart';
import 'package:fctech/services/image_cache_service.dart';
import 'package:fctech/services/local_database_service.dart';


// Exemplo de uso do widget CachedNetworkImage personalizado


class OfflineModePage extends StatelessWidget {
  @override

    final ImageCacheService _imageCacheService = ImageCacheService();

    final LocalDatabaseService _localDatabaseService = LocalDatabaseService('users');

    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: Text('Conteúdo Local')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _localDatabaseService.getAllContent('my_content'),
          builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
            if (snapshot.hasData) {
              List<Map<String, dynamic>> contentList = snapshot.data!;
              return ListView.builder(
                itemCount: contentList.length,
                itemBuilder: (BuildContext context, int index) {
                  print(contentList[index]['username']);
                  return ListTile(
                    title: Text(contentList[index]['username']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: ' + contentList[index]['email']),
                        Text('Name: ' + contentList[index]['name']),
                        Text('Phone: ' + contentList[index]['phone']),
                        Text('Mobile Phone: ' + contentList[index]['mobilePhone']),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward),
                    onTap: () {
                      // Navigate to the detail page for this content item
                    },
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('Erro ao carregar os dados.'));
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      );
    }

  }

