import 'dart:convert';
import 'package:chronora/core/models/service_model.dart';
import 'package:chronora/core/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPageController {
	List<Service> services = [];
	bool isLoading = true;
	String errorMessage = '';

	double tempoValue = 5.0;
	String avaliacaoValue = "0";
	String ordenacaoValue = "0";

	Future<void> carregarServicos() async {
		try {
			final token = await _getToken();
			if (token == null) {
				isLoading = false;
				errorMessage = "Você precisa estar logado.";
				return;
			}

			final res = await ApiService.get('/service/get/all', token: token);
			if (res.statusCode == 200) {
				final List<dynamic> data = json.decode(res.body);
				services = data.map((e) => Service.fromJson(e)).toList();
				isLoading = false;
			} else {
				isLoading = false;
				errorMessage = "Erro ao carregar serviços.";
			}
		} catch (_) {
			isLoading = false;
			errorMessage = "Falha ao carregar serviços.";
		}
	}

	Future<String?> _getToken() async {
		final prefs = await SharedPreferences.getInstance();
		return prefs.getString('auth_token');
	}
}