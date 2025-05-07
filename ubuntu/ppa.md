# How to Publish on PPA?

This article is an abstract of the steps needed to reproduce the process of **how to upload a package to the PPA** (Personal Package Archive).

## Process

1. First you need to create an account in [launchpad](https://launchpad.net/) website.

2. [Activate a new PPA](https://help.launchpad.net/Packaging/PPA#Activating_a_PPA). Go to your [profile page](https://launchpad.net/people/+me/) on launchpad and click on the button `Create a new PPA`. Then complete the form with url, name and description.

> **NOTE:** launchpad generates a unique key for each PPA in the form like `ppa:your_account/your_ppa_name`.

3. [Create your GPG key](https://help.launchpad.net/YourAccount/ImportingYourPGPKey#Using_GPG_to_manage_OpenPGP_keys) to sign source code. Follow next steps:

  - Open a terminal a generate a new GPG key running next command:
    ```sh
    gpg --gen-key
    ```

    > **NOTE:** complete the questions with your real name and email registered in launchpad.net.
  - Add the GPG key generated in previous step to `.bashrc` at the end of the file:
    ```sh
    export GPGKEY="YOUR_GPG_KEY_HERE"
    ```
  - Publish the GPG key to the ubuntu key server:
    ```sh
    gpg --keyserver keyserver.ubuntu.com --send-keys YOUR_GPG_KEY_HERE
    ```
  - Import the fingerprint of your GPG key into launchpad. For this, first get the fingerprint with the command `gpg --fingerprint` and paste it into [next link](https://launchpad.net/people/+me/+editpgpkeys) and press `Import` button.
  - Check your email to confirm your the GPG key that you have generated it. In the email received, copy the encripted text begging with `-----BEGIN PGP MESSAGE-----` and paste it in a text file. Then use next command to obtain confirmation link: `gpg -d your-text-file` 
  - Open the previous link in a web browser and confirm your GPG Key.

4. [Create a SSH key](https://help.launchpad.net/YourAccount/CreatingAnSSHKeyPair) and link it to launchpad. Follow next steps:

  - Install OpenSSH in your system:
    ```sh
    sudo apt-get install openssh-client
    ```
  - Generate a new SSH key with the next command:
    ```sh
    ssh-keygen -t rsa
    ```

    > **NOTE:** press ENTER to accept default values.
  - Get your public SSH key using next command `cat ~/.ssh/id_rsa.pub` and paste it in your [launchpad page](https://launchpad.net/~/+editsshkeys).
  - Click on `Import` button to acept the SSH key.

5. Prepare the source file and update the `debian/changelog` file.

  - Get the latest release of LightPad:
    ```sh
    git clone https://github.com/libredeb/lightpad.git
    git checkout v0.0.9
    ```
  - Generate `orig` source code, so run next commands:
    ```sh
    cp -r lightpad lightpad-0.0.9
    rm -rf lightpad-0.0.9/debian
    tar -cvf com.github.libredeb.lightpad_0.0.9.orig.tar.gz lightpad-0.0.9/
    ```
  - Putting things in their place:
    ```sh
    rm -rf lightpad-0.0.9/
    mv lightpad lightpad-0.0.9
    ```
  - Update the `debian/changelog` file to match with your distribution codename.
  - Build required files to upload the packate to your PPA:
    ```sh
    cd lightpad-0.0.9/
    debuild -S -sa
    ```

    > **NOTE:** before finishing, the process will ask you for the password of your GPG key. 

6. [Upload the package to your PPA](https://help.launchpad.net/Packaging/PPA/Uploading). Complete these steps:
  - Finally upload the package to the PPA:
    ```sh
    dput ppa:your_account/your_ppa_name com.github.libredeb.lightpad_0.0.9-3_source.changes
    ```
  - Then you need to wait to launchpad compile your package and generate deb files (is not immediate).
