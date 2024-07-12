package notification

import (
	"fmt"
	"os/exec"
)

func DisplayNotification(message, title string) {
	cmd := exec.Command("osascript", "-e", fmt.Sprintf(`display notification "%s" with title "%s"`, message, title))
	cmd.Run()
}
