package com.phucdnh.navigationiq.parser

/**
 * Utility matching strings for exit navigation, rerouting, and end trip across languages.
 * Ported from com.navigationparser.lib.Parsing.Maps.Utils.
 */
object MapsUtils {
    val EXIT_NAVIGATION = hashSetOf(
        "Exit navigation", "Thoát chế đi theo chỉ dẫn", "Quitter la navigation",
        "Salir de la navegación", "Navigation beenden", "Avsluta navigering",
        "Esci dal Navigatore", "Завершить", "结束导航", "結束導航", "ナビを終了",
        "Keluar navigasi", "Sair da navegação", "Navigasyondan çık", "ออกจากการนำทาง",
        "내비게이션 종료", "Ukončit navigaci", "Zakończ nawigację"
    )

    val END_TRIP = hashSetOf(
        "End trip", "End ride", "Kết thúc chuyến đi", "Mettre fin au trajet",
        "Finalizar trayecto", "Fahrt beenden", "Terminar viagem", "Закончить поездку",
        "结束行程", "結束行程", "経路案内を終了", "Akhiri perjalanan", "경로 안내 종료"
    )

    val REROUTING = hashSetOf(
        "Rerouting...", "Rerouting…", "Đang đổi tuyến đường...", "Calcul du nouvel itinéraire…",
        "Redirigiendo...", "Route wird neu berechnet...", "A redirecionar...",
        "Обновление маршрута…", "正在更改路线…", "正在重新規劃路線…",
        "経路の再検索中...", "Mengubah rute...", "경로 변경 중..."
    )

    fun containsMapsCarDirections(values: NotificationValues): Boolean {
        for (button in values.buttons.values) {
            val text = button?.text?.toString() ?: continue
            if (EXIT_NAVIGATION.any { text.contains(it, ignoreCase = true) }) {
                for (t in values.texts.values) {
                    if (REROUTING.any { t.contains(it, ignoreCase = true) }) {
                        return false
                    }
                }
                return true
            }
        }
        return values.texts.containsKey("android-title") && values.texts.containsKey("android-subText")
    }

    fun containsMapsPTDirections(values: NotificationValues): Boolean {
        val stopButton = values.buttons["actions-action_stop-action_stop_text"]
        val text = stopButton?.text?.toString() ?: return false
        return END_TRIP.any { text.contains(it, ignoreCase = true) }
    }
}
