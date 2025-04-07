import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Crear la ventana y configurar el ViewController principal
        window = UIWindow(windowScene: windowScene)
        let viewController = ViewController()
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Llamado cuando la escena se desconecta
        // Este método es llamado poco después de que la escena entra en segundo plano o se descarta su sesión
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Llamado cuando la escena ha pasado de un estado inactivo a activo
        // Aquí puedes reiniciar cualquier tarea que se haya pausado (o que aún no haya comenzado) cuando la escena estaba inactiva
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Llamado cuando la escena va a pasar de un estado activo a inactivo
        // Esto puede ocurrir debido a interrupciones temporales (por ejemplo, una llamada telefónica entrante)
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Llamado mientras la escena está transicionando del fondo al primer plano
        // Aquí puedes deshacer los cambios realizados al entrar en el fondo
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Llamado mientras la escena está transicionando del primer plano al fondo
        // Aquí puedes guardar los datos, liberar recursos compartidos y almacenar suficiente estado de escena específico para restaurar la escena a su estado actual
    }
}

