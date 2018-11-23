try:
    import unicornhathd
    print("unicorn hat hd detected")
except ImportError:
    from unicorn_hat_sim import unicornhathd

def main():

    try:
        unicornhathd.rotation(0)
        while True:

            unicornhathd.set_pixel(abs(1 - 15), 0, 255,255,255)

            unicornhathd.show()

    except KeyboardInterrupt:
        unicornhathd.off()

if __name__ == '__main__':
    main()