# Gitlab Installer

> Easy to use bash files to pre and post configure VPS and install Gitlab.
>
> This is currently tested on Scaleway dev instances.

## Usage

### Installer

```bash
curl https://git.io/gitlab-installer | sudo bash
```

### Add Swapfile

> You might have to add a swapfile to your instance. You can use this bash file to add.
>
> By default, it's set to **1GB**, you can download and make changes to fit your requirements.

```bash
curl https://git.io/add-swapfile | sudo bash
```

### Restore Backup

> If you're migrating your Gitlab instance from one server to another, then this might come handy for you.
>
> Please download and update vars with appropriate values.

```bash
curl https://git.io/restore-backup

# After updating values
./restore-backup.sh
```

## Security

If you discover any security related issues, please email `syed at lukonet.com` instead of using the issue tracker.

## License

The MIT License (MIT). Please see [License File](LICENSE.md) for more information.
